import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_env.dart';
import '../models/daily_log_model.dart';
import '../models/profile_model.dart';
import '../models/recurring_transaction_model.dart';

/// Gemini 2.5 Flash ile Oracle AI chatbot sohbeti yönetir.
/// Her [GeminiService] örneği bağımsız bir sohbet geçmişi tutar.
class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppEnv.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.75,
        maxOutputTokens: 1000,
        topP: 0.95,
      ),
      systemInstruction: Content.system(
        '''Sen FortuneFlow AI Oracle'sın — kişisel finans uzmanı, bilge bir asistan.
Kullanıcıya samimi, net ve XAI (Açıklanabilir AI) odaklı yanıtlar ver. 
Yanıtların 2-4 cümle olsun. Karmaşık finansal durumları metaforlarla açıkla. ''',
      ),
    );
    _chat = _model.startChat();
  }

  /// Kullanıcı finansal verisiyle zenginleştirilmiş sistem bağlamını başlatır.
  /// Bu metodu [sendMessage]'dan önce bir kez çağırın.
  Future<void> initializeContext({
    required ProfileModel profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> recentLogs,
  }) async {
    final context = _buildSystemContext(
      profile: profile,
      transactions: transactions,
      recentLogs: recentLogs,
    );

    // İlk mesaj olarak sistem bağlamını gönderiyoruz
    await _chat.sendMessage(Content.text(context));
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

  String _buildSystemContext({
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

    final transactionLines = transactions
        .map((t) {
          final sign = t.isIncome ? '+' : '-';
          return '  $sign${t.amount.toStringAsFixed(0)} TL ${t.category}';
        })
        .join('\n');

    final logLines = recentLogs
        .take(7)
        .map((l) {
          return '  ${l.date.day}/${l.date.month}: ${l.spentAmount.toStringAsFixed(0)} TL harcandı, '
              '${l.transferredToSavings.toStringAsFixed(0)} TL havuza aktarıldı';
        })
        .join('\n');

    return '''
Sen FortuneFlow AI Oracle'sın — kişisel finans alanında uzmanlaşmış, Türkçe konuşan bir yapay zeka asistanısın.
Kullanıcıya samimi, net ve aksiyon odaklı yanıtlar ver. Finansal terimler kullan ama anlaşılır tut.
Yanıtlarını kısa tut (2-4 cümle). Eğer simülasyon veya grafik önereceğin durumlar olursa belirt.

─── KULLANICI PROFİLİ ───
Ad: ${profile.userName}
Yaş: ${profile.age} | Cinsiyet: ${profile.gender}
Seviye: ${profile.level} | XP: ${profile.xp}

─── FİNANSAL DURUM ───
Güncel Bakiye: ${profile.currentBalance.toStringAsFixed(2)} TL
Tasarruf Havuzu: ${profile.savingsPool.toStringAsFixed(2)} TL
Günlük Harcama Limiti: ${profile.dailyLimit.toStringAsFixed(2)} TL
Başlangıç Bakiyesi: ${profile.initialBalance.toStringAsFixed(2)} TL

─── AYLIK DÜZENLİ İŞLEMLER ───
Toplam Gelir: +${income.toStringAsFixed(0)} TL
Toplam Gider: -${expense.toStringAsFixed(0)} TL
Net Aylık: ${(income - expense).toStringAsFixed(0)} TL
Detay:
$transactionLines

─── SON 7 GÜN ───
$logLines

Bu verilerle kullanıcıya kişiselleştirilmiş finansal tavsiye ver.
''';
  }
}
