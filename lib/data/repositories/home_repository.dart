import '../datasources/local_datasource.dart';
import '../models/crisis_event_model.dart';
import '../models/daily_log_model.dart';
import '../models/recurring_transaction_model.dart';
import '../services/supabase_service.dart';

class HomeFinanceSnapshot {
  final double currentBalance;
  final double savingsPool;
  final List<CrisisEventModel> crisisEvents;

  const HomeFinanceSnapshot({
    required this.currentBalance,
    required this.savingsPool,
    required this.crisisEvents,
  });
}

class HomeRepository {
  final LocalDataSource _localDataSource;
  final SupabaseService _supabaseService;

  HomeRepository({
    LocalDataSource? localDataSource,
    SupabaseService? supabaseService,
  }) : _localDataSource = localDataSource ?? LocalDataSource(),
       _supabaseService = supabaseService ?? SupabaseService.instance;

  Future<void> reconcileDailySavingsAndXp({int lookbackDays = 30}) async {
    final userId = _supabaseService.currentUserId;
    if (userId != null) {
      try {
        await _supabaseService.reconcileDailySavingsAndXp(
          userId: userId,
          lookbackDays: lookbackDays,
        );
      } catch (_) {}
      return;
    }

    try {
      await _localDataSource.reconcileDailySavingsAndXp(
        lookbackDays: lookbackDays,
      );
    } catch (_) {}
  }

  Future<List<RecurringTransactionModel>> getRecurringTransactions() {
    return _localDataSource.getRecurringTransactions();
  }

  Future<String> getPreferredCurrency() {
    return _localDataSource.getPreferredCurrency();
  }

  Future<HomeFinanceSnapshot> getFinanceSnapshot() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      return const HomeFinanceSnapshot(
        currentBalance: 0,
        savingsPool: 0,
        crisisEvents: [],
      );
    }

    double currentBalance = 0;
    double savingsPool = 0;
    List<CrisisEventModel> crisisEvents = const [];

    final profile = await _supabaseService.getProfile(userId);
    if (profile != null) {
      currentBalance = profile.currentBalance;
      savingsPool = await _supabaseService.getSavingsTotal(userId);
    }

    try {
      final delta = await _supabaseService.applyDueRules(userId);
      if (delta != 0) {
        currentBalance = (currentBalance + delta).clamp(0.0, double.maxFinite);
      }
    } catch (_) {}

    try {
      crisisEvents = await _supabaseService.getCrisisEvents(userId);
    } catch (_) {
      crisisEvents = const [];
    }

    return HomeFinanceSnapshot(
      currentBalance: currentBalance,
      savingsPool: savingsPool,
      crisisEvents: crisisEvents,
    );
  }

  Future<double> getTodayTransferredToSavings() async {
    final userId = _supabaseService.currentUserId;
    final today = DateTime.now();

    List<DailyLogModel> logs;
    if (userId != null) {
      try {
        logs = await _supabaseService.getRecentDailyLogs(userId, days: 1);
      } catch (_) {
        logs = await _localDataSource.getRecentDailyLogs(days: 1);
      }
    } else {
      logs = await _localDataSource.getRecentDailyLogs(days: 1);
    }

    return logs
        .where(
          (l) =>
              l.date.year == today.year &&
              l.date.month == today.month &&
              l.date.day == today.day,
        )
        .fold<double>(0, (sum, l) => sum + l.transferredToSavings);
  }

  Future<void> updateXpAndLevel({
    required String userId,
    required int xp,
    required int level,
  }) async {
    await _supabaseService.updateProfile(userId, {'xp': xp, 'level': level});
  }
}
