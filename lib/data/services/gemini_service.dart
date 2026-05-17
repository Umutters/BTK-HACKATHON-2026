import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_env.dart';
import '../models/daily_log_model.dart';
import '../models/profile_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/recurring_transaction_model.dart';

/// Gemini 2.5 Flash ile kâhin sohbetini yönetir.
/// Her [GeminiService] örneği bağımsız bir sohbet geçmişi tutar.
class GeminiService {
  GenerativeModel _model;
  ChatSession _chat;

  static const _baseInstruction =
      'Sen FortuneFlow kişisel finans AI asistanısın. Türkçe yanıt ver.';

  GeminiService()
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppEnv.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
          topP: 0.95,
        ),
        systemInstruction: Content.system(_baseInstruction),
      ),
      _chat = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppEnv.geminiApiKey,
        systemInstruction: Content.system(_baseInstruction),
      ).startChat();

  /// Kullanıcının gerçek Supabase verisiyle model sistem talimatını yeniden
  /// oluşturur ve sohbeti sıfırlar. sendMessage öncesi çağrılmalı.
  Future<void> initializeContext({
    required ProfileModel profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> recentLogs,
    List<RecurringRuleModel> rules = const [],
    String goalName = '',
  }) async {
    final systemInstruction = _buildSystemInstruction(
      profile: profile,
      transactions: transactions,
      recentLogs: recentLogs,
      rules: rules,
      goalName: goalName,
    );

    // Gerçek kullanıcı verisiyle yeni bir model + chat oturumu aç
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppEnv.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
        topP: 0.95,
      ),
      systemInstruction: Content.system(systemInstruction),
    );
    _chat = _model.startChat();
  }

  /// Kullanıcı mesajını Gemini'ye gönderir ve AI yanıtını döndürür.
  /// API key tanımlı değilse demo yanıt döndürür.
  Future<String> sendMessage(String userMessage) async {
    if (AppEnv.geminiApiKey.isEmpty) {
      return _demoResponse(userMessage);
    }
    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      return response.text ?? 'Yanıt alınamadı, lütfen tekrar deneyin.';
    } catch (e) {
      final raw = e.toString();
      final lower = raw.toLowerCase();

      // API kaynaklı hataları kullanıcıya net bir dille ilet.
      if (lower.contains('api key expired') ||
          lower.contains('invalid api key') ||
          lower.contains('unauthenticated') ||
          lower.contains('permission denied')) {
        return 'Gemini anahtarı geçersiz veya süresi dolmuş görünüyor. Lütfen yeni anahtar üretip uygulamayı tamamen yeniden başlat.';
      }

      if (lower.contains('quota') ||
          lower.contains('resource exhausted') ||
          lower.contains('rate limit') ||
          lower.contains('too many requests') ||
          lower.contains('(429)') ||
          lower.contains(' 429 ')) {
        return 'Gemini kotası dolmuş görünüyor. Bir süre bekleyip tekrar dene veya plan/kota ayarlarını kontrol et.';
      }

      if (lower.contains('503') ||
          lower.contains('unavailable') ||
          lower.contains('high demand') ||
          lower.contains('service unavailable')) {
        return 'Gemini şu an yoğun talep nedeniyle geçici olarak yanıt veremiyor. Birkaç saniye bekleyip tekrar dene.';
      }

      if (lower.contains('network') ||
          lower.contains('socket') ||
          lower.contains('timed out')) {
        return 'Ağ bağlantısında sorun var. İnternet bağlantını kontrol edip tekrar dene.';
      }

      return 'Gemini yanıtı alınamadı. Teknik detay: $raw';
    }
  }

  /// Action butonları için: tüm verileri prompt içine gömer, doğrudan
  /// gemini-2.0-flash generateContent çağırır — chat session'a bağımlı değil.
  Future<String> generateDirectAnalysis({
    required ProfileModel profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> recentLogs,
    required List<RecurringRuleModel> rules,
    required String goalName,
    required String question,
  }) async {
    if (AppEnv.geminiApiKey.isEmpty) return _demoResponse(question);

    final income = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    final savings = transactions
        .where((t) => t.isSaving)
        .fold(0.0, (s, t) => s + t.amount);
    final net = income - expense - savings;

    final expenseLines = transactions
        .where((t) => t.isExpense)
        .map((t) => '  ${t.category}: ${t.amount.toStringAsFixed(0)} TL/ay')
        .join('\n');
    final incomeLines = transactions
        .where((t) => t.isIncome)
        .map((t) => '  ${t.category}: ${t.amount.toStringAsFixed(0)} TL/ay')
        .join('\n');

    final sortedLogs = [...recentLogs]
      ..sort((a, b) => b.date.compareTo(a.date));
    final avgDaily = sortedLogs.isNotEmpty
        ? sortedLogs.fold(0.0, (s, l) => s + l.spentAmount) / sortedLogs.length
        : 0.0;
    final overLimit = sortedLogs
        .where((l) => l.spentAmount > profile.dailyLimit)
        .length;
    final logSummary = sortedLogs
        .take(10)
        .map((l) {
          final flag = l.spentAmount > profile.dailyLimit
              ? ' [LİMİT AŞILDI]'
              : '';
          return '  ${l.date.day}/${l.date.month}: ${l.spentAmount.toStringAsFixed(0)} TL$flag';
        })
        .join('\n');

    final activeRules = rules.where((r) => r.isActive).toList();
    final ruleExpLines = activeRules
        .where((r) => r.isExpense)
        .map(
          (r) =>
              '  ${r.category}${r.description != null && r.description!.isNotEmpty ? " (${r.description})" : ""}: ${r.amount.toStringAsFixed(0)} TL/${_freqLabel(r.frequency)}',
        )
        .join('\n');
    final ruleIncLines = activeRules
        .where((r) => r.isIncome)
        .map(
          (r) =>
              '  ${r.category}: ${r.amount.toStringAsFixed(0)} TL/${_freqLabel(r.frequency)}',
        )
        .join('\n');

    final prompt =
        '''Sen FortuneFlow kişisel finans AI asistanısın. YALNIZCA aşağıdaki gerçek verilere dayanarak Türkçe yanıt ver. Genel tavsiye VERME, sadece bu kullanıcının rakamlarını kullan.

KULLANICI: ${profile.userName} | Bakiye: ${profile.currentBalance.toStringAsFixed(0)} TL | Tasarruf havuzu: ${profile.savingsPool.toStringAsFixed(0)} TL | Günlük limit: ${profile.dailyLimit.toStringAsFixed(0)} TL
Aylık gelir: ${income.toStringAsFixed(0)} TL | Aylık gider: ${expense.toStringAsFixed(0)} TL | Aylık tasarruf kesintisi: ${savings.toStringAsFixed(0)} TL | Net aylık fazla: ${net.toStringAsFixed(0)} TL
${goalName.isNotEmpty ? 'Hedef: $goalName' : ''}

GELİR KALEMLERİ:
${incomeLines.isEmpty ? '  (kayıt yok)' : incomeLines}

GİDER KALEMLERİ:
${expenseLines.isEmpty ? '  (kayıt yok)' : expenseLines}

SON ${sortedLogs.length} GÜN GÜNLÜK HARCAMA (limit: ${profile.dailyLimit.toStringAsFixed(0)} TL/gün):
Ortalama: ${avgDaily.toStringAsFixed(0)} TL/gün | Limit aşan gün sayısı: $overLimit
${logSummary.isEmpty ? '  (log yok)' : logSummary}

${activeRules.isNotEmpty ? '''DÜZENLİ GELİR KURALLARI:
${ruleIncLines.isEmpty ? '  (yok)' : ruleIncLines}

DÜZENLİ GİDER KURALLARI:
${ruleExpLines.isEmpty ? '  (yok)' : ruleExpLines}''' : ''}

SORU: $question

KURAL: Yanıtta sadece bu kullanıcının TL rakamlarını kullan. Markdown yıldız (*) kullanma. 3-5 cümle, her cümlede somut sayı olsun.''';

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppEnv.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.5,
          maxOutputTokens: 2800,
          topP: 0.9,
        ),
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) return _demoResponse(question);
      return text.trim();
    } catch (e) {
      final raw = e.toString().toLowerCase();
      if (raw.contains('503') ||
          raw.contains('unavailable') ||
          raw.contains('high demand')) {
        return 'Gemini şu an yoğun talep nedeniyle geçici olarak yanıt veremiyor. Birkaç saniye bekleyip tekrar dene.';
      }
      if (raw.contains('quota') || raw.contains('429')) {
        return 'Gemini kotası dolmuş görünüyor. Bir süre bekleyip tekrar dene.';
      }
      return _demoResponse(question);
    }
  }

  Future<String> generateSimulationInsight({
    required ProfileModel profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> recentLogs,
    required String goalName,
    required double goalMillions,
    required int goalYear,
    required double projectedMillions,
    required double monthlySurplus,
    required List<String> topDrivers,
  }) async {
    if (AppEnv.geminiApiKey.isEmpty) {
      return _demoSimulationInsight(
        goalName: goalName,
        goalYear: goalYear,
        projectedMillions: projectedMillions,
        monthlySurplus: monthlySurplus,
      );
    }

    final topDriverText = topDrivers.isEmpty
        ? '- Belirgin kalem etkisi bulunamadı.'
        : topDrivers.map((d) => '- $d').join('\n');

    final income = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);

    final fullPrompt =
        '''Sen kısa ve net Türkçe finans yorumu yapan bir asistansın. Yalnızca tek cümle yaz.

Kullanıcı: ${profile.userName} | Bakiye: ${profile.currentBalance.toStringAsFixed(0)} TL | Günlük limit: ${profile.dailyLimit.toStringAsFixed(0)} TL
Aylık gelir: ${income.toStringAsFixed(0)} TL | Aylık gider: ${expense.toStringAsFixed(0)} TL | Net surplus: ${monthlySurplus.toStringAsFixed(0)} TL
Hedef: $goalName — ${goalMillions.toStringAsFixed(1)}M TL | Tahmini ulaşma: $goalYear | Uzun vadeli projeksiyon: ${projectedMillions.toStringAsFixed(1)}M TL

En etkili kalemler:
$topDriverText

Kural: 120 karakteri geçme. Somut TL rakamı kullan. Fırsat maliyeti, nakit akışı ve toparlanma hızından birini vurgula. Markdown kullanma.''';

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppEnv.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 512,
          topP: 0.9,
        ),
      );
      final response = await model.generateContent([Content.text(fullPrompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return _demoSimulationInsight(
          goalName: goalName,
          goalYear: goalYear,
          projectedMillions: projectedMillions,
          monthlySurplus: monthlySurplus,
        );
      }
      return text.trim();
    } catch (e) {
      final raw = e.toString().toLowerCase();
      if (raw.contains('503') ||
          raw.contains('unavailable') ||
          raw.contains('high demand')) {
        return 'Gemini şu an yoğun. Birkaç saniye bekleyip tekrar dene.';
      }
      return _demoSimulationInsight(
        goalName: goalName,
        goalYear: goalYear,
        projectedMillions: projectedMillions,
        monthlySurplus: monthlySurplus,
      );
    }
  }

  /// Hızlı işlem ekranındaki kısa etki metni için Gemini analizi.
  /// Başarısız olursa null döner; çağıran taraf lokal fallback kullanır.
  Future<String?> generateQuickTransactionPreview({
    required String entryType,
    required String category,
    required double amount,
    required double currentBalance,
    required double savingsPool,
    required double dailyLimit,
  }) async {
    if (AppEnv.geminiApiKey.isEmpty) return null;

    final prompt =
        '''Türkçe konuşan kişisel finans asistanısın. Kullanıcı hızlı işlem giriyor.

İşlem tipi: $entryType
Kategori: $category
Tutar: ${amount.toStringAsFixed(0)} TL
Mevcut bakiye: ${currentBalance.toStringAsFixed(0)} TL
Birikim havuzu: ${savingsPool.toStringAsFixed(0)} TL
Günlük limit: ${dailyLimit.toStringAsFixed(0)} TL

Görev:
- Kullanıcıya bu işlemin kısa etkisini tek cümleyle anlat.
- Somut sayı kullan.
- En fazla 120 karakter yaz.
- Sadece düz metin döndür, yıldız veya markdown kullanma.''';

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppEnv.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          maxOutputTokens: 120,
          topP: 0.9,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text.replaceAll('\n', ' ');
    } catch (_) {
      return null;
    }
  }

  /// Hızlı işlem ekranındaki Gemini Scan butonu için kısa analiz üretir.
  /// Başarısız olursa null döner, böylece çağıran taraf yerel fallback kullanır.
  Future<String?> generateQuickScanAnalysis({
    required String entryType,
    required String category,
    required double amount,
    required double currentBalance,
    required double savingsPool,
    required double dailyLimit,
  }) async {
    if (AppEnv.geminiApiKey.isEmpty) return null;

    final prompt =
        '''Türkçe konuşan kişisel finans AI asistanısın. Kullanıcının hızlı işlem ekranındaki girdisini analiz et.

İşlem tipi: $entryType
Kategori: $category
Tutar: ${amount.toStringAsFixed(0)} TL
Mevcut bakiye: ${currentBalance.toStringAsFixed(0)} TL
Birikim havuzu: ${savingsPool.toStringAsFixed(0)} TL
Günlük limit: ${dailyLimit.toStringAsFixed(0)} TL

Görev:
- Sadece 1 kısa paragraf yaz.
- Kullanıcının işleminin finansal etkisini yorumla.
- Somut sayı kullan.
- En fazla 140 karakter yaz.
- Sadece düz metin döndür, markdown kullanma.''';

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppEnv.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.45,
          maxOutputTokens: 140,
          topP: 0.9,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text.replaceAll('\n', ' ');
    } catch (_) {
      return null;
    }
  }

  String _demoResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('tasarruf') || lower.contains('birikim')) {
      return 'Tasarruf havuzunu büyütmek için günlük limitine sadık kalman yeterli. Küçük tutarlar bile bileşik etkiyle zamanla ciddi bir sermayeye dönüşür.';
    }
    if (lower.contains('harcama') || lower.contains('limit')) {
      return 'Günlük limitini aşmamak XP kazanmanın en hızlı yolu. Limitin altında kalan her kuruş otomatik olarak tasarruf havuzuna aktarılıyor.';
    }
    if (lower.contains('kriz') || lower.contains('acil')) {
      return 'Beklenmedik giderler için önce tasarruf havuzunu kullan. Bu sayede bütçeni bozmadan krizi atlatabilirsin.';
    }
    if (lower.contains('yatırım') || lower.contains('getiri')) {
      return 'Yatırım kararı vermeden önce en az 3 aylık acil fon oluşturmanı öneririm. Güvenli zemin olmadan risk almak sermayeyi eritebilir.';
    }
    return 'Finansal durumunu analiz ediyorum. Simülasyon ekranından 20 yıllık projeksiyon görüntüleyebilir, farklı senaryolar deneyebilirsin.';
  }

  String _demoSimulationInsight({
    required String goalName,
    required int goalYear,
    required double projectedMillions,
    required double monthlySurplus,
  }) {
    final trend = monthlySurplus >= 0 ? 'pozitif' : 'negatif';
    return '$goalName için trend $trend; bu rotada $goalYear civarında yaklaşık ${projectedMillions.toStringAsFixed(1)}M TL görebilirsin ve aylık katkını 1000 TL artırman toparlanmayı belirgin hızlandırır.';
  }

  String _freqLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'gün';
      case 'weekly':
        return 'hafta';
      case 'yearly':
        return 'yıl';
      default:
        return 'ay';
    }
  }

  String _buildSystemInstruction({
    required ProfileModel profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> recentLogs,
    List<RecurringRuleModel> rules = const [],
    String goalName = '',
  }) {
    final income = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final savingsTx = transactions
        .where((t) => t.isSaving)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netMonthly = income - expense - savingsTx;

    final sortedLogs = [...recentLogs]
      ..sort((a, b) => a.date.compareTo(b.date));
    final totalSpent = sortedLogs.fold(0.0, (sum, l) => sum + l.spentAmount);
    final totalSavedLogs = sortedLogs.fold(
      0.0,
      (sum, l) => sum + l.transferredToSavings,
    );
    final avgDailySpend = sortedLogs.isNotEmpty
        ? totalSpent / sortedLogs.length
        : 0.0;
    final daysAboveLimit = sortedLogs
        .where((l) => l.spentAmount > profile.dailyLimit)
        .length;
    final daysBelowLimit = sortedLogs.length - daysAboveLimit;

    final incomeLines = transactions
        .where((t) => t.isIncome)
        .map((t) => '  • ${t.category}: +${t.amount.toStringAsFixed(0)} TL/ay')
        .join('\n');
    final expenseLines = transactions
        .where((t) => t.isExpense)
        .map((t) => '  • ${t.category}: -${t.amount.toStringAsFixed(0)} TL/ay')
        .join('\n');
    final savingLines = transactions
        .where((t) => t.isSaving)
        .map((t) => '  • ${t.category}: ${t.amount.toStringAsFixed(0)} TL/ay')
        .join('\n');

    final logLines = sortedLogs.reversed
        .take(14)
        .map((l) {
          final over = l.spentAmount > profile.dailyLimit
              ? ' ⚠ limit aşıldı'
              : '';
          return '  ${l.date.day}/${l.date.month}: harcama ${l.spentAmount.toStringAsFixed(0)} TL'
              ' | havuz +${l.transferredToSavings.toStringAsFixed(0)} TL$over';
        })
        .join('\n');

    final activeRules = rules.where((r) => r.isActive).toList();
    final ruleIncomeLines = activeRules
        .where((r) => r.isIncome)
        .map((r) {
          final freq = _freqLabel(r.frequency);
          final desc = (r.description?.isNotEmpty == true)
              ? ' (${r.description})'
              : '';
          return '  • ${r.category}$desc: +${r.amount.toStringAsFixed(0)} TL/$freq';
        })
        .join('\n');
    final ruleExpenseLines = activeRules
        .where((r) => r.isExpense)
        .map((r) {
          final freq = _freqLabel(r.frequency);
          final desc = (r.description?.isNotEmpty == true)
              ? ' (${r.description})'
              : '';
          return '  • ${r.category}$desc: -${r.amount.toStringAsFixed(0)} TL/$freq';
        })
        .join('\n');

    final today = DateTime.now();

    return '''
Sen "FortuneFlow" uygulamasının kişisel finans AI asistanısın. Türkçe yanıt ver.

TEMEL KURALLAR:
• Aşağıdaki GERÇEK kullanıcı verilerini kullanarak yanıt ver — genel tavsiye verme.
• Her yanıtta en az bir somut sayıya (TL, %, gün) değin.
• Kullanıcının adını (${profile.userName}) zaman zaman kullan.
• Yanıtları 2-4 cümle tut; kritik uyarıları öne al.
• Önemli rakamları **kalın** yaz.
• Kullanıcı simülasyon veya grafik isterse "Simülasyon ekranına bakabilirsin" de.
• Bilinmeyen bilgi için veri yetersizliğini belirt, uydurma.

═══ KULLANICI: ${profile.userName} ═══
Yaş: ${profile.age} | Cinsiyet: ${profile.gender}
Seviye: Lv${profile.level} | XP: ${profile.xp}

─── ANLK FİNANSAL DURUM (${today.day}/${today.month}/${today.year}) ───
💰 Güncel Bakiye   : ${profile.currentBalance.toStringAsFixed(0)} TL
🏦 Tasarruf Havuzu : ${profile.savingsPool.toStringAsFixed(0)} TL
📅 Günlük Limit    : ${profile.dailyLimit.toStringAsFixed(0)} TL
📊 Aylık Net Fazla : ${netMonthly.toStringAsFixed(0)} TL
📈 Başlangıç Bak.  : ${profile.initialBalance.toStringAsFixed(0)} TL
🔄 Net Değişim     : ${(profile.currentBalance - profile.initialBalance).toStringAsFixed(0)} TL

─── AYLIK GELİRLER (+${income.toStringAsFixed(0)} TL) ───
${incomeLines.isEmpty ? '  (kayıt yok)' : incomeLines}

─── AYLIK GİDERLER (-${expense.toStringAsFixed(0)} TL) ───
${expenseLines.isEmpty ? '  (kayıt yok)' : expenseLines}
${savingLines.isNotEmpty ? '\n─── TASARRUF KESİNTİLERİ (${savingsTx.toStringAsFixed(0)} TL) ───\n$savingLines\n' : ''}
─── SON ${sortedLogs.length} GÜN ANALİZİ ───
Toplam harcama   : ${totalSpent.toStringAsFixed(0)} TL
Ortalama/gün     : ${avgDailySpend.toStringAsFixed(0)} TL  (limit: ${profile.dailyLimit.toStringAsFixed(0)} TL)
Havuza aktarılan : ${totalSavedLogs.toStringAsFixed(0)} TL
Limit aşan gün   : $daysAboveLimit  |  Limit altı gün: $daysBelowLimit

${logLines.isEmpty ? '  (log kaydı yok)' : logLines}
${activeRules.isNotEmpty ? '''
─── DÜZENLİ GELİR/GİDER KURALLARI ───
Düzenli gelirler:
${ruleIncomeLines.isEmpty ? '  (kayıt yok)' : ruleIncomeLines}
Düzenli giderler:
${ruleExpenseLines.isEmpty ? '  (kayıt yok)' : ruleExpenseLines}
''' : ''}${goalName.isNotEmpty ? '─── FİNANSAL HEDEF ───\nHedef: $goalName\n' : ''}
''';
  }
}
