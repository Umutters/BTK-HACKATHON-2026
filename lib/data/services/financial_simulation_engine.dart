import 'dart:math';

import '../models/crisis_event_model.dart';
import '../models/crisis_marker.dart';
import '../models/daily_log_model.dart';
import '../models/decision_log_model.dart';
import '../models/profile_model.dart';
import '../models/projection_point.dart';
import '../models/recurring_rule_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/simulation_series_point.dart';
import '../models/transaction_impact.dart';

class SimulationComputationResult {
  final double monthlySurplus;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlySavingsTransfer;
  final double monthlyNetCashflow;
  final double savingsRatePercent;
  final double emergencyRunwayMonths;
  final double safeMonthlyBudget;
  final double avgDailyTransferred30;
  final double avgDailyTransferred7;
  final double goalMillions;
  final List<ProjectionPoint> currentPoints;
  final List<ProjectionPoint> optimizedPoints;
  final List<SimulationSeriesPoint> currentSeries;
  final List<SimulationSeriesPoint> optimizedSeries;
  final List<CrisisMarker> crisisMarkers;
  final List<TransactionImpact> transactionImpacts;

  const SimulationComputationResult({
    required this.monthlySurplus,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavingsTransfer,
    required this.monthlyNetCashflow,
    required this.savingsRatePercent,
    required this.emergencyRunwayMonths,
    required this.safeMonthlyBudget,
    required this.avgDailyTransferred30,
    required this.avgDailyTransferred7,
    required this.goalMillions,
    required this.currentPoints,
    required this.optimizedPoints,
    required this.currentSeries,
    required this.optimizedSeries,
    required this.crisisMarkers,
    required this.transactionImpacts,
  });
}

class FinancialSimulationEngine {
  final DateTime Function() _now;

  const FinancialSimulationEngine({required DateTime Function() now})
    : _now = now;

  SimulationComputationResult compute({
    required ProfileModel? profile,
    required List<RecurringTransactionModel> transactions,
    required List<RecurringRuleModel> rules,
    required List<DailyLogModel> logs,
    required List<CrisisEventModel> crisisEvents,
    required List<DecisionLogModel> decisionLogs,
    required int routeYears,
    required double extraDailySavings,
    required double annualReturnRateSlider,
    required double defaultAnnualReturnRate,
    required String goalId,
  }) {
    final sortedLogs = [...logs]..sort((a, b) => b.date.compareTo(a.date));

    double _ruleMonthly(RecurringRuleModel r) {
      switch (r.frequency) {
        case 'daily':
          return r.amount * 30;
        case 'weekly':
          return r.amount * 4.33;
        case 'yearly':
          return r.amount / 12;
        default:
          return r.amount;
      }
    }

    final activeRules = rules.where((r) => r.isActive).toList();
    final ruleMonthlyIncome = activeRules
        .where((r) => r.isIncome)
        .fold<double>(0, (sum, r) => sum + _ruleMonthly(r));
    final ruleMonthlyExpense = activeRules
        .where((r) => r.isExpense)
        .fold<double>(0, (sum, r) => sum + _ruleMonthly(r));

    final monthlyIncome =
        transactions
            .where((t) => t.isIncome)
            .fold<double>(0, (sum, t) => sum + t.amount) +
        ruleMonthlyIncome;
    final monthlyExpense =
        transactions
            .where((t) => t.isExpense)
            .fold<double>(0, (sum, t) => sum + t.amount) +
        ruleMonthlyExpense;

    final avgDailyTransferred30 = _averageDailyTransfer(sortedLogs);
    final avgDailyTransferred7 = _averageDailyTransfer(sortedLogs.take(7));

    final rawMonthlySavingsTransfer = avgDailyTransferred30 * 30;
    final monthlySavingsTransfer = monthlyIncome <= 0
        ? rawMonthlySavingsTransfer
        : rawMonthlySavingsTransfer.clamp(0.0, monthlyIncome);

    // Net nakit akışında transferi ikinci kez gider yazmayız;
    // transfer ayrı metrik olarak gösteriliyor.
    final monthlyNetCashflow = monthlyIncome - monthlyExpense;

    final monthlySurplus = _estimateMonthlySurplus(
      transactions: transactions,
      rules: rules,
      monthlySavingsTransfer: monthlySavingsTransfer,
    );

    final safeMonthlyBudget = max(0.0, monthlyIncome - monthlyExpense);
    final savingsRatePercent = monthlyIncome <= 0
        ? 0.0
        : ((monthlySavingsTransfer / monthlyIncome) * 100).clamp(0.0, 100.0);
    final emergencyExpenseBase = max(
      monthlyExpense,
      (profile?.dailyLimit ?? 0) * 30,
    );
    final emergencyRunwayMonths = emergencyExpenseBase <= 0 || profile == null
        ? 0.0
        : profile.savingsPool / emergencyExpenseBase;
    final baseAmount = _estimateBaseWealth(profile);
    final baseMonthlyContribution = monthlySavingsTransfer;

    final currentSeries = _buildScenarioSeries(
      initialAmount: baseAmount,
      monthlyContribution: baseMonthlyContribution,
      annualRate: defaultAnnualReturnRate,
      routeYears: routeYears,
      crisisEvents: crisisEvents,
      decisionLogs: decisionLogs,
      optimized: false,
    );

    final optimizedSeries = _buildScenarioSeries(
      initialAmount: baseAmount,
      monthlyContribution: baseMonthlyContribution + (extraDailySavings * 30),
      annualRate: annualReturnRateSlider,
      routeYears: routeYears,
      crisisEvents: crisisEvents,
      decisionLogs: decisionLogs,
      optimized: true,
    );

    final currentPoints = _sampleAnnualPoints(currentSeries);
    final optimizedPoints = _sampleAnnualPoints(optimizedSeries);
    final crisisMarkers = _buildCrisisMarkers(
      crisisEvents: crisisEvents,
      routeYears: routeYears,
    );
    final transactionImpacts = _buildTransactionImpacts(
      transactions: transactions,
      logs: logs,
      profile: profile,
    );

    final startMillions = currentPoints.isNotEmpty
        ? currentPoints.first.amountMillions
        : 0;
    final goalMultiplier = _goalMultiplierFor(goalId);
    final trendBoost = max(0, monthlySurplus) * 24;
    final goalFromProfile = (profile?.initialBalance ?? 0) * goalMultiplier;
    final fallbackGoal = max(150000, max(goalFromProfile, trendBoost));
    final goalMillions = max(
      startMillions + 0.1,
      fallbackGoal / 1000000,
    ).clamp(0.2, 20.0);

    return SimulationComputationResult(
      monthlySurplus: monthlySurplus,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlySavingsTransfer: monthlySavingsTransfer,
      monthlyNetCashflow: monthlyNetCashflow,
      savingsRatePercent: savingsRatePercent,
      emergencyRunwayMonths: emergencyRunwayMonths,
      safeMonthlyBudget: safeMonthlyBudget,
      avgDailyTransferred30: avgDailyTransferred30,
      avgDailyTransferred7: avgDailyTransferred7,
      goalMillions: goalMillions,
      currentPoints: currentPoints,
      optimizedPoints: optimizedPoints,
      currentSeries: currentSeries,
      optimizedSeries: optimizedSeries,
      crisisMarkers: crisisMarkers,
      transactionImpacts: transactionImpacts,
    );
  }

  double _estimateBaseWealth(ProfileModel? profile) {
    if (profile == null) return 50000;
    return max(0, profile.savingsPool);
  }

  double _estimateMonthlySurplus({
    required List<RecurringTransactionModel> transactions,
    required List<RecurringRuleModel> rules,
    required double monthlySavingsTransfer,
  }) {
    double _ruleMonthly(RecurringRuleModel r) {
      switch (r.frequency) {
        case 'daily':
          return r.amount * 30;
        case 'weekly':
          return r.amount * 4.33;
        case 'yearly':
          return r.amount / 12;
        default:
          return r.amount;
      }
    }

    final activeRules = rules.where((r) => r.isActive).toList();
    final recurringIncome =
        transactions
            .where((t) => t.isIncome)
            .fold<double>(0, (sum, t) => sum + t.amount) +
        activeRules
            .where((r) => r.isIncome)
            .fold<double>(0, (sum, r) => sum + _ruleMonthly(r));

    final recurringExpense =
        transactions
            .where((t) => t.isExpense)
            .fold<double>(0, (sum, t) => sum + t.amount) +
        activeRules
            .where((r) => r.isExpense)
            .fold<double>(0, (sum, r) => sum + _ruleMonthly(r));

    return recurringIncome - recurringExpense - monthlySavingsTransfer;
  }

  double _averageDailyTransfer(Iterable<DailyLogModel> logs) {
    final values = logs
        .map((l) => max(0.0, l.transferredToSavings))
        .where((v) => v.isFinite)
        .toList();

    if (values.isEmpty) return 0.0;
    values.sort();

    if (values.length < 5) {
      return values.fold<double>(0, (sum, v) => sum + v) / values.length;
    }

    final trim = max(1, (values.length * 0.1).floor());
    final start = trim;
    final end = values.length - trim;
    if (start >= end) {
      return values.fold<double>(0, (sum, v) => sum + v) / values.length;
    }

    final trimmed = values.sublist(start, end);
    return trimmed.fold<double>(0, (sum, v) => sum + v) / trimmed.length;
  }

  List<SimulationSeriesPoint> _buildScenarioSeries({
    required double initialAmount,
    required double monthlyContribution,
    required double annualRate,
    required int routeYears,
    required List<CrisisEventModel> crisisEvents,
    required List<DecisionLogModel> decisionLogs,
    required bool optimized,
  }) {
    final months = max(12, routeYears * 12);
    final monthlyRate = annualRate / 12;
    final startDate = DateTime(_now().year, _now().month, 1);
    final shocks = _buildCrisisShockSchedule(
      crisisEvents: crisisEvents,
      months: months,
    );
    final totalXp = decisionLogs.fold<int>(0, (sum, log) => sum + log.xpGained);

    var value = max(0.0, initialAmount);
    var currentPmt = max(0.0, monthlyContribution);
    final points = <SimulationSeriesPoint>[];

    for (var month = 0; month <= months; month++) {
      if (month > 0) {
        value = value * (1 + monthlyRate) + currentPmt;

        final shock = shocks[month];
        if (shock != null) {
          value = max(0.0, value - shock.amount);
          currentPmt += _recoveryBoostFor(
            shock.amount,
            shock.strategy,
            optimized: optimized,
            totalXp: totalXp,
          );
        }
      }

      points.add(
        SimulationSeriesPoint(
          monthIndex: month,
          date: DateTime(startDate.year, startDate.month + month, 1),
          amountMillions: value / 1000000,
        ),
      );
    }

    return points;
  }

  Map<int, _CrisisShock> _buildCrisisShockSchedule({
    required List<CrisisEventModel> crisisEvents,
    required int months,
  }) {
    final schedule = <int, _CrisisShock>{};
    final startDate = DateTime(_now().year, _now().month, 1);

    for (final event in crisisEvents) {
      final eventDate = event.createdAt ?? _now();
      final monthIndex = max(
        1,
        ((eventDate.year - startDate.year) * 12 +
                (eventDate.month - startDate.month))
            .clamp(0, months),
      );
      schedule[monthIndex] = _CrisisShock(
        amount: event.amount,
        strategy: event.resolutionStrategy,
      );
    }

    return schedule;
  }

  List<CrisisMarker> _buildCrisisMarkers({
    required List<CrisisEventModel> crisisEvents,
    required int routeYears,
  }) {
    final startDate = DateTime(_now().year, _now().month, 1);
    return crisisEvents.map((event) {
      final eventDate = event.createdAt ?? _now();
      final monthIndex = max(
        1,
        ((eventDate.year - startDate.year) * 12 +
                (eventDate.month - startDate.month))
            .clamp(0, routeYears * 12),
      );
      return CrisisMarker(
        monthIndex: monthIndex,
        date: DateTime(startDate.year, startDate.month + monthIndex, 1),
        label: '${event.eventName} ${event.amount.toStringAsFixed(0)} TL',
      );
    }).toList();
  }

  List<ProjectionPoint> _sampleAnnualPoints(
    List<SimulationSeriesPoint> monthlySeries,
  ) {
    final sampled = <ProjectionPoint>[];
    for (final point in monthlySeries) {
      if (point.monthIndex % 12 == 0) {
        sampled.add(ProjectionPoint(point.date.year, point.amountMillions));
      }
    }

    if (sampled.isEmpty && monthlySeries.isNotEmpty) {
      sampled.add(
        ProjectionPoint(
          monthlySeries.first.date.year,
          monthlySeries.first.amountMillions,
        ),
      );
      sampled.add(
        ProjectionPoint(
          monthlySeries.last.date.year,
          monthlySeries.last.amountMillions,
        ),
      );
    }

    return sampled;
  }

  List<TransactionImpact> _buildTransactionImpacts({
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> logs,
    required ProfileModel? profile,
  }) {
    final rows = <TransactionImpact>[];

    for (final t in transactions) {
      final signedMonthly = (t.isIncome || t.isSaving) ? t.amount : -t.amount;
      rows.add(
        TransactionImpact(
          category: t.category,
          type: t.type,
          monthlyImpact: signedMonthly,
          annualImpact: signedMonthly * 12,
          sharePercent: 0,
        ),
      );
    }

    if (logs.isNotEmpty) {
      final avgDailySpent =
          logs.fold<double>(0, (sum, l) => sum + l.spentAmount) / logs.length;
      rows.add(
        TransactionImpact(
          category: 'Gunluk Harcama Ortalamasi',
          type: 'expense',
          monthlyImpact: -(avgDailySpent * 30),
          annualImpact: -(avgDailySpent * 30 * 12),
          sharePercent: 0,
        ),
      );

      final avgDailyTransfer =
          logs.fold<double>(0, (sum, l) => sum + l.transferredToSavings) /
          logs.length;
      rows.add(
        TransactionImpact(
          category: 'Birikim Aktarim Ortalamasi',
          type: 'saving',
          monthlyImpact: avgDailyTransfer * 30,
          annualImpact: avgDailyTransfer * 30 * 12,
          sharePercent: 0,
        ),
      );
    } else if ((profile?.dailyLimit ?? 0) > 0) {
      final fallbackMonthlySpend = (profile!.dailyLimit * 30 * 0.8);
      rows.add(
        TransactionImpact(
          category: 'Tahmini Gunluk Harcama',
          type: 'expense',
          monthlyImpact: -fallbackMonthlySpend,
          annualImpact: -fallbackMonthlySpend * 12,
          sharePercent: 0,
        ),
      );
    }

    final totalAbsAnnual = rows.fold<double>(
      0,
      (sum, e) => sum + e.annualImpact.abs(),
    );

    final withShare = rows
        .map(
          (e) => TransactionImpact(
            category: e.category,
            type: e.type,
            monthlyImpact: e.monthlyImpact,
            annualImpact: e.annualImpact,
            sharePercent: totalAbsAnnual == 0
                ? 0
                : (e.annualImpact.abs() / totalAbsAnnual) * 100,
          ),
        )
        .toList();

    withShare.sort(
      (a, b) => b.annualImpact.abs().compareTo(a.annualImpact.abs()),
    );
    return withShare;
  }

  double _recoveryBoostFor(
    double shockAmount,
    String strategy, {
    required bool optimized,
    required int totalXp,
  }) {
    final xpFactor = min(0.25, totalXp / 5000);
    final strategyFactor = switch (strategy) {
      'budget' => 0.02,
      'pool' => 0.008,
      _ => 0.012,
    };
    final optimizedFactor = optimized ? 1.0 : 0.35;
    return shockAmount * (strategyFactor + xpFactor * 0.02) * optimizedFactor;
  }

  double _goalMultiplierFor(String goalId) {
    switch (goalId) {
      case 'debt':
        return 1.2;
      case 'emergency':
        return 1.5;
      case 'education':
        return 1.8;
      case 'family':
        return 2.0;
      case 'digital':
        return 2.2;
      case 'startup':
        return 2.7;
      default:
        return 2.0;
    }
  }
}

class _CrisisShock {
  final double amount;
  final String strategy;

  const _CrisisShock({required this.amount, required this.strategy});
}
