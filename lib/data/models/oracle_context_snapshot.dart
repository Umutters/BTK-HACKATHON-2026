import 'daily_log_model.dart';
import 'profile_model.dart';
import 'recurring_rule_model.dart';
import 'recurring_transaction_model.dart';

class OracleContextSnapshot {
  final ProfileModel? profile;
  final List<RecurringTransactionModel> transactions;
  final List<DailyLogModel> logs;
  final List<RecurringRuleModel> rules;
  final String goalName;

  const OracleContextSnapshot({
    required this.profile,
    required this.transactions,
    required this.logs,
    required this.rules,
    required this.goalName,
  });
}
