import '../data/models/daily_log_model.dart';
import '../data/models/profile_model.dart';
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
      final userId = SupabaseService.instance.currentUserId;
      if (userId != null) {
        final profile = await _dataSource.getUserProfile();
        final transactions = await _dataSource.getRecurringTransactions();
        final logs = await _dataSource.getRecentDailyLogs(days: 30);

        // Cache et
        _cachedProfile = profile;
        _cachedTransactions = transactions;
        _cachedLogs = logs;

        await _gemini.initializeContext(
          profile: profile,
          transactions: transactions,
          recentLogs: logs,
        );
        _contextLoaded = true;

        final income = transactions
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = transactions
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount);

        _addOracleMessage(
          'Merhaba **${profile.userName}**! Verilerini yükledim.\n'
          '💰 Bakiye: **${profile.currentBalance.toStringAsFixed(0)} TL** | '
          '🏦 Havuz: **${profile.savingsPool.toStringAsFixed(0)} TL** | '
          '📊 Aylık net: **${(income - expense).toStringAsFixed(0)} TL**\n'
          'Ne analiz edelim?',
          actionButtons: ['Günlük analiz yap', 'Tasarruf önerisi'],
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
      actionButtons: ['Günlük analiz yap', 'Tasarruf önerisi'],
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
      final userId = SupabaseService.instance.currentUserId;
      if (userId != null) {
        final profile = await _dataSource.getUserProfile();
        final transactions = await _dataSource.getRecurringTransactions();
        final logs = await _dataSource.getRecentDailyLogs(days: 30);

        _cachedProfile = profile;
        _cachedTransactions = transactions;
        _cachedLogs = logs;

        await _gemini.initializeContext(
          profile: profile,
          transactions: transactions,
          recentLogs: logs,
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
          '📊 **${(income - expense).toStringAsFixed(0)} TL** aylık net',
          actionButtons: ['Günlük analiz yap', 'Tasarruf önerisi'],
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
