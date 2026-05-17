import 'dart:async';

import '../data/datasources/local_datasource.dart';
import '../data/models/crisis_event_model.dart';
import '../data/models/daily_log_model.dart';
import '../data/models/profile_model.dart';
import '../data/models/recurring_rule_model.dart';
import '../data/models/recurring_transaction_model.dart';
import 'package:flutter/foundation.dart';

import '../data/datasources/supabase_datasource.dart';
import '../data/services/gemini_service.dart';
import '../data/services/supabase_service.dart';

enum MessageSender { oracle, user }

class DataCard {
  final String label;
  final String value;
  final double progress; // 0.0 - 1.0

  const DataCard({
    required this.label,
    required this.value,
    required this.progress,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final List<String>? actionButtons;
  final DataCard? dataCard;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.actionButtons,
    this.dataCard,
  });
}

class OracleViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isOracleTyping = false;
  bool _isInitialized = false;
  String? _initError;

  // Supabase'den çekilen veriyi cache'le — clearChat yeniden init edebilsin
  ProfileModel? _cachedProfile;
  List<RecurringTransactionModel> _cachedTransactions = [];
  List<DailyLogModel> _cachedLogs = [];
  List<RecurringRuleModel> _cachedRules = [];
  String _cachedGoalName = '';

  // ─── Kriz yönetimi ───────────────────────────────────────────────────
  CrisisEventModel? _pendingCrisis;
  CrisisEventModel? _scheduledCrisisInjection;

  final GeminiService _gemini;
  final SupabaseDataSource _dataSource;
  final LocalDataSource _localDataSource;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isOracleTyping => _isOracleTyping;
  bool get isInitialized => _isInitialized;
  String? get initError => _initError;

  OracleViewModel({
    GeminiService? gemini,
    SupabaseDataSource? dataSource,
    LocalDataSource? localDataSource,
  }) : _gemini = gemini ?? GeminiService(),
       _dataSource = dataSource ?? SupabaseDataSource(),
       _localDataSource = localDataSource ?? LocalDataSource() {
    _initialize();
  }

  void _clearCachedContext() {
    _cachedProfile = null;
    _cachedTransactions = [];
    _cachedLogs = [];
    _cachedRules = [];
    _cachedGoalName = '';
  }

  Future<void> _initialize() async {
    try {
      ProfileModel? profile;
      List<RecurringTransactionModel> transactions = [];
      List<DailyLogModel> logs = [];
      List<RecurringRuleModel> rules = [];

      // Önce Supabase'den çek, başarısız olursa yerel cache'e düş
      try {
        final userId = SupabaseService.instance.currentUserId;
        if (userId != null) {
          profile = await _dataSource.getUserProfile();
          transactions = await _dataSource.getRecurringTransactions();
          logs = await _dataSource.getRecentDailyLogs(days: 30);
          rules = await _dataSource.getRecurringRules();
        }
      } catch (_) {
        profile = null; // Supabase başarısız → local'e düş
      }

      // Supabase başarısız olduysa veya userId null ise local cache kullan
      if (profile == null) {
        profile = await _localDataSource.getProfile();
        transactions = await _localDataSource.getRecurringTransactions();
        logs = await _localDataSource.getRecentDailyLogs(days: 30);
        rules = await _localDataSource.getRecurringRules();
      }

      final selectedGoal = await _localDataSource.getSelectedGoal();
      final goalName = (selectedGoal['goalName'] ?? '').trim();

      if (profile != null) {
        _cachedProfile = profile;
        _cachedTransactions = transactions;
        _cachedLogs = logs;
        _cachedRules = rules;
        _cachedGoalName = goalName;

        await _gemini.initializeContext(
          profile: profile,
          transactions: transactions,
          recentLogs: logs,
          rules: rules,
          goalName: goalName,
        );

        final income = transactions
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = transactions
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount);

        _addOracleMessage(
          'Merhaba **${profile.userName}**! Tüm finansal verilerini yükledim.\n'
          '💰 Bakiye: **${profile.currentBalance.toStringAsFixed(0)} TL** | '
          '🏦 Havuz: **${profile.savingsPool.toStringAsFixed(0)} TL** | '
          '📊 Aylık net: **${(income - expense).toStringAsFixed(0)} TL**'
          '${goalName.isNotEmpty ? ' | \ud83c\udfaf Hedef: **$goalName**' : ''}\n'
          'Ne analiz edelim?',
          actionButtons: [
            'Harcama analizimi yap',
            'Hedefime ne zaman ulaşırım?',
            'Tasarruf önerisi ver',
            'Düzenli giderlerimi incele',
          ],
        );
      } else {
        _clearCachedContext();
        _seedFallbackMessages();
      }
    } catch (e) {
      _initError = e.toString();
      _clearCachedContext();
      if (_messages.isEmpty) _seedFallbackMessages();
    } finally {
      _isInitialized = true;
      // Eğer bekleyen bir kriz injeksiyonu varsa şimdi çalıştır
      if (_scheduledCrisisInjection != null) {
        final crisis = _scheduledCrisisInjection!;
        _scheduledCrisisInjection = null;
        if (_cachedProfile != null) {
          unawaited(_doInjectCrisis(crisis));
        } else {
          _addOracleMessage(
            'Kriz analizi için finansal profil verileri yüklenemedi. Lütfen sohbeti yenileyip tekrar dene.',
          );
        }
      }
      notifyListeners();
    }
  }

  void _seedFallbackMessages() {
    _addOracleMessage(
      'Merhaba! Finansal verilerini analiz etmeye hazırım. Ne öğrenmek istersin?',
      actionButtons: [
        'Harcama analizimi yap',
        'Tasarruf önerisi ver',
        'Düzenli giderlerimi incele',
      ],
    );
  }

  void _addOracleMessage(
    String text, {
    List<String>? actionButtons,
    DataCard? dataCard,
  }) {
    _messages.add(
      ChatMessage(
        id: 'oracle_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        sender: MessageSender.oracle,
        timestamp: DateTime.now(),
        actionButtons: actionButtons,
        dataCard: dataCard,
      ),
    );
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
    // Supabase'den taze veri çek ve Gemini'yi yeniden başlat
    _reinitialize();
  }

  Future<void> _reinitialize() async {
    try {
      ProfileModel? profile;
      List<RecurringTransactionModel> transactions = [];
      List<DailyLogModel> logs = [];
      List<RecurringRuleModel> rules = [];

      try {
        final userId = SupabaseService.instance.currentUserId;
        if (userId != null) {
          profile = await _dataSource.getUserProfile();
          transactions = await _dataSource.getRecurringTransactions();
          logs = await _dataSource.getRecentDailyLogs(days: 30);
          rules = await _dataSource.getRecurringRules();
        }
      } catch (_) {
        profile = null;
      }

      if (profile == null) {
        profile = await _localDataSource.getProfile();
        transactions = await _localDataSource.getRecurringTransactions();
        logs = await _localDataSource.getRecentDailyLogs(days: 30);
        rules = await _localDataSource.getRecurringRules();
      }

      final selectedGoal = await _localDataSource.getSelectedGoal();
      final goalName = (selectedGoal['goalName'] ?? '').trim();

      if (profile != null) {
        _cachedProfile = profile;
        _cachedTransactions = transactions;
        _cachedLogs = logs;
        _cachedRules = rules;
        _cachedGoalName = goalName;

        await _gemini.initializeContext(
          profile: profile,
          transactions: transactions,
          recentLogs: logs,
          rules: rules,
          goalName: goalName,
        );

        final income = transactions
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = transactions
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount);

        _addOracleMessage(
          'Sohbet sıfırlandı. Güncel verilerini yeniden yükledim.\n'
          '💰 **${profile.currentBalance.toStringAsFixed(0)} TL** bakiye | '
          '🏦 **${profile.savingsPool.toStringAsFixed(0)} TL** havuz | '
          '📊 **${(income - expense).toStringAsFixed(0)} TL** aylık net'
          '${goalName.isNotEmpty ? ' | \ud83c\udfaf **$goalName**' : ''}',
          actionButtons: [
            'Harcama analizimi yap',
            'Hedefime ne zaman ulaşırım?',
            'Tasarruf önerisi ver',
            'Düzenli giderlerimi incele',
          ],
        );
      } else {
        _clearCachedContext();
        _seedFallbackMessages();
      }
    } catch (e) {
      _clearCachedContext();
      _seedFallbackMessages();
    } finally {
      notifyListeners();
    }
  }

  // ─── Kriz Enjeksiyonu ────────────────────────────────────────────────────────

  /// Dashboard'dan tetiklenir: kriz olayını Oracle'a inject eder.
  /// Oracle henüz init olmadıysa, init tamamlanınca otomatik çalışır.
  Future<void> injectCrisisEvent(CrisisEventModel crisis) async {
    if (!_isInitialized) {
      _scheduledCrisisInjection = crisis;
      return;
    }

    if (_cachedProfile == null) {
      _addOracleMessage(
        'Kriz senaryosu için gerekli finansal veriler hazır değil. Lütfen sohbeti yenileyip tekrar dene.',
      );
      notifyListeners();
      return;
    }

    await _doInjectCrisis(crisis);
  }

  Future<void> _doInjectCrisis(CrisisEventModel crisis) async {
    _pendingCrisis = crisis;

    final amountStr = crisis.amount.toStringAsFixed(0);
    final balanceStr = _cachedProfile?.currentBalance.toStringAsFixed(0) ?? '?';
    final poolStr = _cachedProfile?.savingsPool.toStringAsFixed(0) ?? '?';
    final disciplineEvidence = _buildSevenDayDisciplineEvidence();
    final disciplineCard = _buildSevenDayDisciplineCard();

    // Kullanıcı mesajı olarak kriz alarmını göster
    _messages.add(
      ChatMessage(
        id: 'crisis_${DateTime.now().millisecondsSinceEpoch}',
        text:
            '🚨 KRİZ ALARMI: "${crisis.eventName}" — $amountStr TL beklenmedik gider!',
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    );
    _isOracleTyping = true;
    notifyListeners();

    final prompt =
        '🚨 KRİZ DURUMU: "${crisis.eventName}" adında beklenmedik bir gider ortaya çıktı — tutar: $amountStr TL\n\n'
        'Kullanıcının mevcut finansal durumu:\n'
        '- Anlık bakiye: $balanceStr TL\n'
        '- Birikim havuzu: $poolStr TL\n\n'
        'Son 7 gün disiplin verisi (XAI kanıtı):\n'
        '$disciplineEvidence\n\n'
        'Bu kriz için iki seçenek var:\n'
        '1. 🏦 Birikim havuzundan karşıla ($poolStr TL mevcut)\n'
        '2. 💰 Anlık bütçeden karşıla ($balanceStr TL mevcut)\n\n'
        'Lütfen şunları analiz et:\n'
        '- İlk paragrafta mutlaka son 7 gün verilerini kullanarak kullanıcıya "yüzleşme" cümlesi kur\n'
        '- Bu krizin uzun vadeli finans planına etkisi nedir?\n'
        '- Hangi stratejiyle karşılamalı ve neden?\n'
        '- Bu durumdan sonra toparlanmak için 1-2 somut öneri ver.\n'
        'Yanıtın 3-4 paragraf uzunluğunda, dramatik ama yapıcı olsun.';

    try {
      final response = await _gemini.generateDirectAnalysis(
        profile: _cachedProfile!,
        transactions: _cachedTransactions,
        recentLogs: _cachedLogs,
        rules: _cachedRules,
        goalName: _cachedGoalName,
        question: prompt,
      );
      _addOracleMessage(
        response,
        actionButtons: ['🏦 Havuzdan Karşıla', '💰 Bütçeden Karşıla'],
        dataCard: disciplineCard,
      );
    } catch (e) {
      _addOracleMessage(
        'Kriz analizi yapılamadı: ${e.toString()}. Kaynağını seçerek devam edebilirsin.',
        actionButtons: ['🏦 Havuzdan Karşıla', '💰 Bütçeden Karşıla'],
        dataCard: disciplineCard,
      );
    } finally {
      _isOracleTyping = false;
      notifyListeners();
    }
  }

  String _buildSevenDayDisciplineEvidence() {
    final profile = _cachedProfile;
    if (profile == null || _cachedLogs.isEmpty || profile.dailyLimit <= 0) {
      return '- Son 7 gün için yeterli log yok.';
    }

    final sorted = [..._cachedLogs]..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(7).toList();
    if (recent.isEmpty) return '- Son 7 gün için yeterli log yok.';

    final over = recent
        .where((l) => l.spentAmount > profile.dailyLimit)
        .toList();
    final underOrEqual = recent.length - over.length;
    final overRate = (over.length / recent.length) * 100;

    final avgOverPct = over.isEmpty
        ? 0.0
        : over
                  .map(
                    (l) =>
                        ((l.spentAmount - profile.dailyLimit) /
                            profile.dailyLimit) *
                        100,
                  )
                  .fold<double>(0, (sum, v) => sum + v) /
              over.length;

    var consecutiveOver = 0;
    for (final log in recent) {
      if (log.spentAmount > profile.dailyLimit) {
        consecutiveOver += 1;
      } else {
        break;
      }
    }

    return '- İncelenen gün: ${recent.length}\n'
        '- Limit: ${profile.dailyLimit.toStringAsFixed(0)} TL/gün\n'
        '- Limit aşımı: ${over.length}/${recent.length} gün (%${overRate.toStringAsFixed(0)})\n'
        '- Limit altı/eşit: $underOrEqual gün\n'
        '- Aşım günlerinde ortalama taşma: %${avgOverPct.toStringAsFixed(0)}\n'
        '- Mevcut aşım serisi: $consecutiveOver gün';
  }

  DataCard? _buildSevenDayDisciplineCard() {
    final profile = _cachedProfile;
    if (profile == null || _cachedLogs.isEmpty || profile.dailyLimit <= 0) {
      return null;
    }

    final sorted = [..._cachedLogs]..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(7).toList();
    if (recent.isEmpty) return null;

    final belowOrEqual = recent
        .where((l) => l.spentAmount <= profile.dailyLimit)
        .length;
    final score = ((belowOrEqual / recent.length) * 100).clamp(0, 100);

    final over = recent
        .where((l) => l.spentAmount > profile.dailyLimit)
        .toList();
    final avgOverPct = over.isEmpty
        ? 0.0
        : over
                  .map(
                    (l) =>
                        ((l.spentAmount - profile.dailyLimit) /
                            profile.dailyLimit) *
                        100,
                  )
                  .fold<double>(0, (sum, v) => sum + v) /
              over.length;

    final multiValue =
        '%${score.toStringAsFixed(0)} | '
        '${over.length}/7 aşım | '
        '+%${avgOverPct.toStringAsFixed(0)}';

    return DataCard(
      label: 'SON 7 GUN DISIPLIN SKORU',
      value: multiValue,
      progress: score / 100,
    );
  }

  Future<void> _resolvePendingCrisis(String strategy) async {
    final crisis = _pendingCrisis;
    if (crisis == null) return;

    final userId = SupabaseService.instance.currentUserId;
    if (userId == null || _cachedProfile == null) {
      _addOracleMessage(
        'Kriz çözümü uygulanamadı: oturum veya profil bilgisi eksik.',
      );
      notifyListeners();
      return;
    }

    _pendingCrisis = null;

    _isOracleTyping = true;
    notifyListeners();

    try {
      final profile = _cachedProfile!;
      var nextBalance = profile.currentBalance;
      var nextPool = profile.savingsPool;

      if (strategy == 'pool') {
        await SupabaseService.instance.addToSavingsPool(userId, -crisis.amount);
        nextPool = (nextPool - crisis.amount).clamp(0.0, double.maxFinite);
      } else {
        final newBalance = (nextBalance - crisis.amount).clamp(
          0.0,
          double.maxFinite,
        );
        await SupabaseService.instance.updateBalance(userId, newBalance);
        nextBalance = newBalance;
      }

      await SupabaseService.instance.updateCrisisResolution(
        crisis.id,
        strategy,
      );

      final newXp = profile.xp + 75;
      await SupabaseService.instance.updateXp(userId, newXp);

      _cachedProfile = ProfileModel(
        id: profile.id,
        userName: profile.userName,
        age: profile.age,
        gender: profile.gender,
        initialBalance: profile.initialBalance,
        currentBalance: nextBalance,
        savingsPool: nextPool,
        level: profile.level,
        xp: newXp,
        dailyLimit: profile.dailyLimit,
      );

      final sourceLabel = strategy == 'pool' ? 'Birikim Havuzu' : 'Bütçe';
      final amountStr = crisis.amount.toStringAsFixed(0);
      _addOracleMessage(
        '✅ **${crisis.eventName}** krizi $sourceLabel\'ndan karşılandı ($amountStr TL).\n'
        '⚡ **+75 XP** kazandın — kriz yönetimi finansal farkındalığın kanıtı.\n'
        'Toparlanma önerilerini uygulamaya başlarsan uzun vadeli etkiyi minimize edersin.',
      );
    } catch (e) {
      _addOracleMessage('İşlem sırasında bir hata oluştu: ${e.toString()}');
    } finally {
      _isOracleTyping = false;
      notifyListeners();
    }
  }

  /// Action butonlarına özel, cache'deki gerçek rakamları içeren zengin prompt gönderir.
  /// Action butonları için: verileri doğrudan gemini-2.0-flash'a gönderir.
  Future<void> sendActionButton(String action) async {
    // Kriz çözüm butonlarını yakala
    if (action.contains('Havuzdan')) {
      await _resolvePendingCrisis('pool');
      return;
    }
    if (action.contains('Bütçeden')) {
      await _resolvePendingCrisis('budget');
      return;
    }

    if (_cachedProfile == null) {
      _addOracleMessage(
        'Finansal verilerine henüz ulaşamadım. Lütfen sohbeti yenile (sağ üst simge) veya internet bağlantını kontrol edip tekrar dene.',
      );
      notifyListeners();
      return;
    }

    // Kullanıcı balonunda kısa buton adı göster
    _messages.add(
      ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        text: action,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    );
    _isOracleTyping = true;
    notifyListeners();

    // Butona özel soru metni — veriler GeminiService içinde prompt'a gömülür
    final questionMap = {
      'Harcama analizimi yap':
          'Harcama analizimi detaylıca yap: en çok harcadığım kategoriler, günlük limit aşımlarım ve somut iyileştirme önerileri.',
      'Hedefime ne zaman ulaşırım?':
          '${_cachedGoalName.isNotEmpty ? '"$_cachedGoalName" hedefime' : 'Hedefime'} mevcut birikim hızımla kaç yılda ulaşabilirim? Hızlandırmak için ne yapabilirim?',
      'Tasarruf önerisi ver':
          'Verilerimi inceleyerek hangi harcama kalemlerinden tasarruf edebilirim? Somut TL tutarları ve pratik adımlar ver.',
      'Düzenli giderlerimi incele':
          'Düzenli gider kurallarımı incele. Hangilerini azaltabilirim veya iptal edebilirim? Toplam ne kadar tasarruf sağlanır?',
    };
    final question = questionMap[action] ?? action;

    try {
      final response = await _gemini.generateDirectAnalysis(
        profile: _cachedProfile!,
        transactions: _cachedTransactions,
        recentLogs: _cachedLogs,
        rules: _cachedRules,
        goalName: _cachedGoalName,
        question: question,
      );
      _addOracleMessage(response);
      _dataSource
          .logDecision(actionTaken: 'Kahin: $action', xpGained: 0)
          .catchError((_) {});
    } catch (e) {
      _addOracleMessage('Yanıt alınamadı: ${e.toString()}');
    } finally {
      _isOracleTyping = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(
      ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        text: text.trim(),
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    );
    _isOracleTyping = true;
    notifyListeners();

    try {
      String response;
      if (_cachedProfile != null) {
        // Profil verisi varsa doğrudan veri tabanlı analiz yap (chat session'a bağımlı değil)
        // Konuşma bağlamını soru içine göm
        final prevMsgs = _messages.sublist(0, _messages.length - 1);
        final recentHistory = prevMsgs.length > 6
            ? prevMsgs.sublist(prevMsgs.length - 6)
            : prevMsgs;

        final String question;
        if (recentHistory.isNotEmpty) {
          final historyText = recentHistory
              .map((m) {
                final who = m.sender == MessageSender.user
                    ? 'Kullanıcı'
                    : 'Kahin';
                final t = m.text.length > 300
                    ? '${m.text.substring(0, 300)}...'
                    : m.text;
                return '$who: $t';
              })
              .join('\n');
          question =
              'Önceki konuşma:\n$historyText\n\nYeni soru: ${text.trim()}';
        } else {
          question = text.trim();
        }

        response = await _gemini.generateDirectAnalysis(
          profile: _cachedProfile!,
          transactions: _cachedTransactions,
          recentLogs: _cachedLogs,
          rules: _cachedRules,
          goalName: _cachedGoalName,
          question: question,
        );
      } else {
        // Veriler henüz yüklenmedi — genel yanıt vermemek için hata göster
        response =
            'Finansal verilerine henüz ulaşamadım. Lütfen sohbeti yenile (sağ üst simge) veya internet bağlantını kontrol edip tekrar dene.';
      }
      _addOracleMessage(response);
      _dataSource
          .logDecision(actionTaken: 'Kahin: $text', xpGained: 0)
          .catchError((_) {});
    } catch (e) {
      _addOracleMessage('Yanıt alınamadı: ${e.toString()}');
    } finally {
      _isOracleTyping = false;
      notifyListeners();
    }
  }
}
