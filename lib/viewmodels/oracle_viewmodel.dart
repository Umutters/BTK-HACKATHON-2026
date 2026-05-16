import '../data/datasources/local_datasource.dart';
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
  bool _contextLoaded = false;

  // Supabase'den çekilen veriyi cache'le — clearChat yeniden init edebilsin
  ProfileModel? _cachedProfile;
  List<RecurringTransactionModel> _cachedTransactions = [];
  List<DailyLogModel> _cachedLogs = [];
  List<RecurringRuleModel> _cachedRules = [];
  String _cachedGoalName = '';

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
        _contextLoaded = true;

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
        _seedFallbackMessages();
      }
    } catch (e) {
      _initError = e.toString();
      if (_messages.isEmpty) _seedFallbackMessages();
    } finally {
      _isInitialized = true;
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
        _contextLoaded = true;

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
        _seedFallbackMessages();
      }
    } catch (e) {
      _seedFallbackMessages();
    } finally {
      notifyListeners();
    }
  }

  /// Action butonlarına özel, cache'deki gerçek rakamları içeren zengin prompt gönderir.
  /// Action butonları için: verileri doğrudan gemini-2.0-flash'a gönderir.
  Future<void> sendActionButton(String action) async {
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
