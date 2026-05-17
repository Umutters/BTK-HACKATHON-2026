import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/recurring_rule_model.dart';
import '../data/repositories/recurring_rules_repository.dart';

enum RecurringRulesState { initial, loading, loaded, error }

class RecurringRulesViewModel extends ChangeNotifier {
  final RecurringRulesRepository _repository;

  RecurringRulesState _state = RecurringRulesState.initial;
  List<RecurringRuleModel> _rules = [];
  String? _errorMessage;

  RecurringRulesViewModel({RecurringRulesRepository? repository})
    : _repository = repository ?? RecurringRulesRepository();

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
      _rules = await _repository.getRules();
      _state = RecurringRulesState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = RecurringRulesState.error;
    }

    notifyListeners();
  }

  Future<void> addRule(RecurringRuleModel rule) async {
    final saved = await _repository.addRule(rule);
    _rules = [saved, ..._rules];
    notifyListeners();
  }

  Future<void> updateRule(RecurringRuleModel updated) async {
    await _repository.updateRule(updated);
    _rules = _rules.map((r) => r.id == updated.id ? updated : r).toList();
    notifyListeners();
  }

  Future<void> deleteRule(String id) async {
    await _repository.deleteRule(id);
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
    final delta = await _repository.checkAndApplyDueRules();
    unawaited(loadRules());
    return delta;
  }
}
