import '../datasources/local_datasource.dart';
import '../datasources/supabase_datasource.dart';
import '../models/daily_log_model.dart';
import '../models/oracle_context_snapshot.dart';
import '../models/profile_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/recurring_transaction_model.dart';
import '../services/supabase_service.dart';

class OracleRepository {
  final SupabaseDataSource _supabaseDataSource;
  final LocalDataSource _localDataSource;

  OracleRepository({
    SupabaseDataSource? supabaseDataSource,
    LocalDataSource? localDataSource,
  }) : _supabaseDataSource = supabaseDataSource ?? SupabaseDataSource(),
       _localDataSource = localDataSource ?? LocalDataSource();

  Future<OracleContextSnapshot> loadContext() async {
    ProfileModel? profile;
    List<RecurringTransactionModel> transactions = const [];
    List<DailyLogModel> logs = const [];
    List<RecurringRuleModel> rules = const [];

    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId != null) {
        profile = await _supabaseDataSource.getUserProfile();
        transactions = await _supabaseDataSource.getRecurringTransactions();
        logs = await _supabaseDataSource.getRecentDailyLogs(days: 30);
        rules = await _supabaseDataSource.getRecurringRules();
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

    return OracleContextSnapshot(
      profile: profile,
      transactions: transactions,
      logs: logs,
      rules: rules,
      goalName: goalName,
    );
  }

  Future<void> logDecision(String actionTaken) async {
    await _supabaseDataSource.logDecision(
      actionTaken: actionTaken,
      xpGained: 0,
    );
  }
}
