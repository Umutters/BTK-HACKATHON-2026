import '../../core/constants/app_env.dart';
import '../datasources/local_datasource.dart';
import '../datasources/supabase_datasource.dart';
import '../models/crisis_event_model.dart';
import '../models/daily_log_model.dart';
import '../models/decision_log_model.dart';
import '../models/profile_model.dart';
import '../models/recurring_transaction_model.dart';

class SimulationGroundedSignals {
  final List<CrisisEventModel> crisisEvents;
  final List<DecisionLogModel> decisionLogs;

  const SimulationGroundedSignals({
    required this.crisisEvents,
    required this.decisionLogs,
  });
}

class SimulationRepository {
  final LocalDataSource _localDataSource;
  final SupabaseDataSource _supabaseDataSource;

  SimulationRepository({
    LocalDataSource? localDataSource,
    SupabaseDataSource? supabaseDataSource,
  }) : _localDataSource = localDataSource ?? LocalDataSource(),
       _supabaseDataSource = supabaseDataSource ?? SupabaseDataSource();

  bool get _canUseSupabase =>
      AppEnv.supabaseUrl.isNotEmpty && AppEnv.supabaseAnonKey.isNotEmpty;

  Future<ProfileModel?> getUserProfile() async {
    if (!_canUseSupabase) return _localDataSource.getProfile();

    try {
      final profile = await _supabaseDataSource.getUserProfile();
      final savingsTotal = await _supabaseDataSource.getSavingsTotal();
      return ProfileModel(
        id: profile.id,
        userName: profile.userName,
        age: profile.age,
        gender: profile.gender,
        initialBalance: profile.initialBalance,
        currentBalance: profile.currentBalance,
        savingsPool: savingsTotal,
        level: profile.level,
        xp: profile.xp,
        dailyLimit: profile.dailyLimit,
      );
    } catch (_) {
      return _localDataSource.getProfile();
    }
  }

  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    if (!_canUseSupabase) return _localDataSource.getRecurringTransactions();

    try {
      final remote = await _supabaseDataSource.getRecurringTransactions();
      if (remote.isNotEmpty) return remote;
    } catch (_) {}

    return _localDataSource.getRecurringTransactions();
  }

  Future<List<DailyLogModel>> getRecentLogs({int days = 30}) async {
    if (!_canUseSupabase) {
      return _localDataSource.getRecentDailyLogs(days: days);
    }

    try {
      final remote = await _supabaseDataSource.getRecentDailyLogs(days: days);
      if (remote.isNotEmpty) return remote;
    } catch (_) {}

    return _localDataSource.getRecentDailyLogs(days: days);
  }

  Future<SimulationGroundedSignals> getGroundedSignals() async {
    if (!_canUseSupabase) {
      return const SimulationGroundedSignals(
        crisisEvents: [],
        decisionLogs: [],
      );
    }

    try {
      final results = await Future.wait([
        _supabaseDataSource.getCrisisEvents(),
        _supabaseDataSource.getDecisionLog(),
      ]);

      return SimulationGroundedSignals(
        crisisEvents: results[0] as List<CrisisEventModel>,
        decisionLogs: results[1] as List<DecisionLogModel>,
      );
    } catch (_) {
      return const SimulationGroundedSignals(
        crisisEvents: [],
        decisionLogs: [],
      );
    }
  }

  Future<String> getPreferredCurrency() =>
      _localDataSource.getPreferredCurrency();

  Future<Map<String, String>> getSelectedGoal() =>
      _localDataSource.getSelectedGoal();
}
