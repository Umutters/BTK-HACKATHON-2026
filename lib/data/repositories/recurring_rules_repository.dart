import '../datasources/local_datasource.dart';
import '../models/recurring_rule_model.dart';
import '../services/supabase_service.dart';

class RecurringRulesRepository {
  final LocalDataSource _localDataSource;
  final SupabaseService _supabaseService;

  RecurringRulesRepository({
    LocalDataSource? localDataSource,
    SupabaseService? supabaseService,
  }) : _localDataSource = localDataSource ?? LocalDataSource(),
       _supabaseService = supabaseService ?? SupabaseService.instance;

  Future<List<RecurringRuleModel>> getRules() async {
    final userId = _supabaseService.currentUserId;
    if (userId != null) {
      try {
        final rules = await _supabaseService.getRecurringRules(userId);
        await _localDataSource.saveRecurringRules(rules);
        return rules;
      } catch (_) {
        return _localDataSource.getRecurringRules();
      }
    }
    return _localDataSource.getRecurringRules();
  }

  Future<RecurringRuleModel> addRule(RecurringRuleModel rule) async {
    final userId = _supabaseService.currentUserId;
    var saved = rule;

    if (userId != null) {
      try {
        saved = await _supabaseService.insertRecurringRule(rule);
      } catch (_) {}
    }

    await _localDataSource.addRecurringRule(saved);
    return saved;
  }

  Future<void> updateRule(RecurringRuleModel updated) async {
    final userId = _supabaseService.currentUserId;

    if (userId != null) {
      try {
        await _supabaseService.updateRecurringRule(updated);
      } catch (_) {}
    }

    await _localDataSource.updateRecurringRule(updated);
  }

  Future<void> deleteRule(String id) async {
    final userId = _supabaseService.currentUserId;

    if (userId != null) {
      try {
        await _supabaseService.deleteRecurringRule(id, userId);
      } catch (_) {}
    }

    await _localDataSource.deleteRecurringRule(id);
  }

  Future<double> checkAndApplyDueRules() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      return _applyDueRulesLocally();
    }

    try {
      return await _supabaseService.applyDueRules(userId);
    } catch (_) {
      return _applyDueRulesLocally();
    }
  }

  Future<double> _applyDueRulesLocally() async {
    final today = DateTime.now();
    final rules = await _localDataSource.getRecurringRules();
    double totalDelta = 0;
    final updated = <RecurringRuleModel>[];

    for (final rule in rules) {
      if (rule.isDueOn(today)) {
        totalDelta += rule.isIncome ? rule.amount : -rule.amount;
        updated.add(rule.copyWith(lastAppliedDate: today));
      } else {
        updated.add(rule);
      }
    }

    if (updated.isNotEmpty) {
      await _localDataSource.saveRecurringRules(updated);
    }

    return totalDelta;
  }
}
