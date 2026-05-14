import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';
import '../data/models/recurring_rule_model.dart';
import '../data/services/supabase_service.dart';

enum RecurringRulesState { initial, loading, loaded, error }

class RecurringRulesViewModel extends ChangeNotifier {
  RecurringRulesState _state = RecurringRulesState.initial;
  List<RecurringRuleModel> _rules = [];
  String? _errorMessage;

  RecurringRulesState get state => _state;
  List<RecurringRuleModel> get rules => List.unmodifiable(_rules);
  String? get errorMessage => _errorMessage;

  List<RecurringRuleModel> get incomeRules =>
      _rules.where((r) => r.isIncome).toList();

  List<RecurringRuleModel> get expenseRules =>
      _rules.where((r) => r.isExpense).toList();

  /// Aylık toplam gelir tahmini (haftalık × 4, günlük × 30, yıllık / 12).
  double get totalMonthlyIncome => _monthlyTotal(incomeRules);

  /// Aylık toplam gider tahmini.
  double get totalMonthlyExpense => _monthlyTotal(expenseRules);

  double _monthlyTotal(List<RecurringRuleModel> list) {
    double total = 0;
    for (final r in list) {
      if (!r.isActive) continue;
      switch (r.frequency) {
        case 'daily':
          total += r.amount * 30;
        case 'weekly':
          total += r.amount * 4;
        case 'monthly':
          total += r.amount;
        case 'yearly':
          total += r.amount / 12;
      }
    }
    return total;
  }

  Future<void> loadRules() async {
    _state = RecurringRulesState.loading;
    notifyListeners();

    try {
      final userId = SupabaseService.instance.currentUserId;
      List<RecurringRuleModel> rules;

      if (userId != null) {
        try {
          rules = await SupabaseService.instance.getRecurringRules(userId);
          // Yerel önbelleğe de kaydet
          await LocalDataSource().saveRecurringRules(rules);
        } catch (_) {
          rules = await LocalDataSource().getRecurringRules();
        }
      } else {
        rules = await LocalDataSource().getRecurringRules();
      }

      _rules = rules;
      _state = RecurringRulesState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = RecurringRulesState.error;
    }

    notifyListeners();
  }

  Future<void> addRule(RecurringRuleModel rule) async {
    final userId = SupabaseService.instance.currentUserId;
    RecurringRuleModel saved = rule;

    if (userId != null) {
      try {
        saved = await SupabaseService.instance.insertRecurringRule(rule);
      } catch (_) {
        // Supabase yoksa local'e düş
      }
    }

    await LocalDataSource().addRecurringRule(saved);
    _rules = [saved, ..._rules];
    notifyListeners();
  }

  Future<void> updateRule(RecurringRuleModel updated) async {
    final userId = SupabaseService.instance.currentUserId;

    if (userId != null) {
      try {
        await SupabaseService.instance.updateRecurringRule(updated);
      } catch (_) {}
    }

    await LocalDataSource().updateRecurringRule(updated);
    _rules = _rules.map((r) => r.id == updated.id ? updated : r).toList();
    notifyListeners();
  }

  Future<void> deleteRule(String id) async {
    final userId = SupabaseService.instance.currentUserId;

    if (userId != null) {
      try {
        await SupabaseService.instance.deleteRecurringRule(id, userId);
      } catch (_) {}
    }

    await LocalDataSource().deleteRecurringRule(id);
    _rules = _rules.where((r) => r.id != id).toList();
    notifyListeners();
  }

  Future<void> toggleActive(String id) async {
    final rule = _rules.firstWhere((r) => r.id == id);
    await updateRule(rule.copyWith(isActive: !rule.isActive));
  }

  /// Vadesi gelen kuralları uygular.
  /// Dönen değer toplam balance deltasıdır (HomeViewModel bunu consume eder).
  Future<double> checkAndApplyDueRules() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return 0;

    try {
      final delta = await SupabaseService.instance.applyDueRules(userId);
      // Local önbelleği Supabase'den tazele
      unawaited(loadRules());
      return delta;
    } catch (_) {
      // Offline: yerel kurallar üzerinde kontrol et
      return _applyDueRulesLocally();
    }
  }

  Future<double> _applyDueRulesLocally() async {
    final today = DateTime.now();
    final rules = await LocalDataSource().getRecurringRules();
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
      await LocalDataSource().saveRecurringRules(updated);
      _rules = updated;
      notifyListeners();
    }

    return totalDelta;
  }
}
