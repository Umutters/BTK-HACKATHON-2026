import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_env.dart';
import '../models/daily_log_model.dart';
import '../models/profile_model.dart';
import '../models/recurring_transaction_model.dart';

/// Gemini 2.0 Flash ile Oracle AI chatbot sohbeti yönetir.
/// Her [GeminiService] örneği bağımsız bir sohbet geçmişi tutar.
class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: AppEnv.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 512,
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
    final response = await _chat.sendMessage(Content.text(userMessage));
    return response.text ?? 'Yanıt alınamadı, lütfen tekrar deneyin.';
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
