import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_env.dart';
import '../models/daily_log_model.dart';
import '../models/profile_model.dart';
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
          maxOutputTokens: 1200,
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
  }) async {
    final systemInstruction = _buildSystemInstruction(
      profile: profile,
      transactions: transactions,
      recentLogs: recentLogs,
    );

    // Gerçek kullanıcı verisiyle yeni bir model + chat oturumu aç
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppEnv.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1200,
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

      if (lower.contains('network') ||
          lower.contains('socket') ||
          lower.contains('timed out')) {
        return 'Ağ bağlantısında sorun var. İnternet bağlantını kontrol edip tekrar dene.';
      }

      return 'Gemini yanıtı alınamadı. Teknik detay: $raw';
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

    await initializeContext(
      profile: profile,
      transactions: transactions,
      recentLogs: recentLogs,
    );

    final topDriverText = topDrivers.isEmpty
        ? '- Belirgin transaction etkisi bulunamadı.'
        : topDrivers.map((d) => '- $d').join('\n');

    final prompt =
        '''
Simülasyon özeti:
- Hedef: $goalName (${goalMillions.toStringAsFixed(2)}M)
- Tahmini varış yılı: $goalYear
- Seçili yılda beklenen portföy: ${projectedMillions.toStringAsFixed(2)}M
- Aylık net surplus: ${monthlySurplus.toStringAsFixed(0)} TL

En etkili transaction kalemleri:
$topDriverText

Lütfen Türkçe ve kısa cevap ver:
1) En kritik 2 aksiyon,
2) Hedefi hızlandırmak için 1 somut sayı önerisi,
3) 1 risk uyarısı.
''';

    return sendMessage(prompt);
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
    return '$goalName hedefi için mevcut trend $trend görünüyor. Bu gidişle $goalYear civarında yaklaşık ${projectedMillions.toStringAsFixed(1)}M seviyesine ulaşma potansiyelin var. Hedefe daha hızlı gitmek için aylık net katkını en az 1000 TL artırmayı dene.';
  }

  String _buildSystemInstruction({
    required ProfileModel profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> recentLogs,
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
''';
  }
}
