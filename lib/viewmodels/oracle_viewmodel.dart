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

  final GeminiService _gemini;
  final SupabaseDataSource _dataSource;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isOracleTyping => _isOracleTyping;
  bool get isInitialized => _isInitialized;
  String? get initError => _initError;

  OracleViewModel({GeminiService? gemini, SupabaseDataSource? dataSource})
    : _gemini = gemini ?? GeminiService(),
      _dataSource = dataSource ?? SupabaseDataSource() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Supabase başlatılmış ve kullanıcı giriş yapmışsa gerçek veri çek
      final userId = SupabaseService.instance.currentUserId;
      if (userId != null) {
        final profile = await _dataSource.getUserProfile();
        final transactions = await _dataSource.getRecurringTransactions();
        final logs = await _dataSource.getRecentDailyLogs();
        await _gemini.initializeContext(
          profile: profile,
          transactions: transactions,
          recentLogs: logs,
        );
        _addOracleMessage(
          'Merhaba ${profile.userName}! Finansal verilerini yükledim. '
          'Güncel bakiyen **${profile.currentBalance.toStringAsFixed(0)} TL**, '
          'tasarruf havuzun **${profile.savingsPool.toStringAsFixed(0)} TL**. '
          'Ne öğrenmek istersin?',
          actionButtons: ['Günlük analiz yap', 'Tasarruf önerisi'],
        );
      } else {
        _seedFallbackMessages();
      }
    } catch (e) {
      // Supabase başlatılmamış veya bağlantı hatası — mock moda geç
      _initError = e.toString();
      if (_messages.isEmpty) _seedFallbackMessages();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _seedFallbackMessages() {
    _messages.addAll([
      ChatMessage(
        id: 'oracle_01',
        text:
            'Güncel volatilite trendlerini analiz ediyorum. **Cyber-Equity** sektöründe asimetrik bir fırsat tespit ettim. Risk-parite simülasyonu çalıştırmak ister misiniz?',
        sender: MessageSender.oracle,
        timestamp: DateTime(2026, 5, 11, 14, 2),
        actionButtons: ['Simülasyonu Çalıştır', 'Piyasa Derin Analizi'],
      ),
      ChatMessage(
        id: 'user_01',
        text:
            'Q3 genişlemesi için mevcut konsolidasyon aşamasını kullanırsak potansiyel ROI\'yi göster.',
        sender: MessageSender.user,
        timestamp: DateTime(2026, 5, 11, 14, 5),
      ),
      ChatMessage(
        id: 'oracle_02',
        text:
            'Projeksiyon tamamlandı. Mevcut trend devam ederse beklenen yıllık getiri **%18-22** aralığında.',
        sender: MessageSender.oracle,
        timestamp: DateTime(2026, 5, 11, 14, 8),
        dataCard: const DataCard(
          label: 'TAHMİNİ GETİRİ',
          value: '+24.8%',
          progress: 0.62,
        ),
      ),
    ]);
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
      final response = await _gemini.sendMessage(text.trim());
      _addOracleMessage(response);
      // Kararı decisions_log tablosuna kaydet — hata olsa da mesajı etkilemesin
      _dataSource
          .logDecision(actionTaken: 'Oracle: $text', xpGained: 0)
          .catchError((_) {});
    } catch (e) {
      _addOracleMessage(
        'Yanıt alınamadı: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}',
      );
    } finally {
      _isOracleTyping = false;
      notifyListeners();
    }
  }
}
