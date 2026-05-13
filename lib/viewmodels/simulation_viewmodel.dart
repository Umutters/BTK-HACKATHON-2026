import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';
import '../data/models/daily_log_model.dart';
import '../data/models/profile_model.dart';
import '../data/models/recurring_transaction_model.dart';
import '../data/services/gemini_service.dart';

class ProjectionPoint {
  final int year;
  final double amountMillions;

  const ProjectionPoint(this.year, this.amountMillions);
}

class TransactionImpact {
  final String category;
  final String type;
  final double monthlyImpact;
  final double annualImpact;
  final double sharePercent;

  const TransactionImpact({
    required this.category,
    required this.type,
    required this.monthlyImpact,
    required this.annualImpact,
    required this.sharePercent,
  });
}

class ProjectionTableRow {
  final int year;
  final double projectedMillions;
  final double goalGapMillions;

  const ProjectionTableRow({
    required this.year,
    required this.projectedMillions,
    required this.goalGapMillions,
  });
}

class SimulationViewModel extends ChangeNotifier {
  final LocalDataSource _localDataSource;
  final GeminiService _geminiService;
  final DateTime Function() _now;

  static const int _projectionYears = 20;
  static const double _annualReturnRate = 0.08;

  late final int _startYear;
  late final int _endYear;

  List<ProjectionPoint> _allPoints = const [];
  List<TransactionImpact> _transactionImpacts = const [];
  double _sliderValue = 0.35;
  bool _isLoading = true;
  bool _isGeneratingAi = false;

  double _goalMillions = 0.0;
  double _monthlySurplus = 0.0;
  String _goalName = 'Finansal Hedef';
  String _goalId = '';
  String? _aiInsightOverride;

  ProfileModel? _profile;
  List<RecurringTransactionModel> _transactions = const [];
  List<DailyLogModel> _logs = const [];

  SimulationViewModel({
    LocalDataSource? localDataSource,
    GeminiService? geminiService,
    DateTime Function()? now,
  }) : _localDataSource = localDataSource ?? LocalDataSource(),
       _geminiService = geminiService ?? GeminiService(),
       _now = now ?? DateTime.now {
    _startYear = _now().year;
    _endYear = _startYear + _projectionYears;
    _bootstrap();
  }

  bool get isLoading => _isLoading;
  bool get isGeneratingAi => _isGeneratingAi;

  double get sliderValue => _sliderValue;
  int get startYear => _startYear;
  int get endYear => _endYear;
  double get goalMillions => _goalMillions;
  String get goalName => _goalName;
  double get monthlySurplus => _monthlySurplus;
  List<TransactionImpact> get transactionImpacts => _transactionImpacts;

  List<ProjectionTableRow> get projectionRows {
    return visiblePoints
        .map(
          (p) => ProjectionTableRow(
            year: p.year,
            projectedMillions: p.amountMillions,
            goalGapMillions: max(0, _goalMillions - p.amountMillions),
          ),
        )
        .toList();
  }

  int get selectedYear {
    return _startYear + (_sliderValue * (_endYear - _startYear)).round();
  }

  List<ProjectionPoint> get visiblePoints {
    return _allPoints.where((p) => p.year <= selectedYear).toList();
  }

  double get targetAmountMillions {
    final pts = visiblePoints;
    if (pts.isEmpty) return 0;
    return pts.last.amountMillions;
  }

  String get formattedTarget {
    final m = targetAmountMillions;
    if (m >= 1000) return '\$${(m / 1000).toStringAsFixed(1)}B';
    if (m >= 1) return '\$${m.toStringAsFixed(1)}M';
    return '\$${(m * 1000).toStringAsFixed(0)}K';
  }

  int get aiGoalYear {
    for (final pt in _allPoints) {
      if (pt.amountMillions >= _goalMillions) return pt.year;
    }
    return _endYear;
  }

  String get aiInsight {
    if (_aiInsightOverride != null && _aiInsightOverride!.trim().isNotEmpty) {
      return _aiInsightOverride!;
    }

    if (_allPoints.isEmpty) {
      return 'Simulation data is loading...';
    }

    final finalAmount = _allPoints.last.amountMillions;
    if (finalAmount >= _goalMillions) {
      return "At this rate, you'll reach your goal by $aiGoalYear.";
    }

    final gapMillions = (_goalMillions - finalAmount).clamp(0, double.infinity);
    final remainingYears = max(1, _endYear - _startYear);
    final suggestedMonthly = ((gapMillions * 1000000) / (remainingYears * 12));

    return 'Current pace reaches ${finalAmount.toStringAsFixed(1)}M by $_endYear. Increase monthly surplus by about ${suggestedMonthly.toStringAsFixed(0)} TL to hit the target earlier.';
  }

  void setSliderValue(double value) {
    _sliderValue = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> generateAiInsight() async {
    if (_profile == null || _allPoints.isEmpty) {
      return;
    }

    _isGeneratingAi = true;
    notifyListeners();

    final topDrivers = _transactionImpacts
        .take(3)
        .map(
          (e) =>
              '${e.category} (${e.type}): ${_formatCompactTl(e.monthlyImpact)}/ay, ${e.sharePercent.toStringAsFixed(0)}%',
        )
        .toList();

    final aiText = await _geminiService.generateSimulationInsight(
      profile: _profile!,
      transactions: _transactions,
      recentLogs: _logs,
      goalName: _goalName,
      goalMillions: _goalMillions,
      goalYear: aiGoalYear,
      projectedMillions: targetAmountMillions,
      monthlySurplus: _monthlySurplus,
      topDrivers: topDrivers,
    );

    _aiInsightOverride = aiText;
    _isGeneratingAi = false;
    notifyListeners();
  }

  Future<void> refresh() => _bootstrap();

  Future<void> _bootstrap() async {
    _isLoading = true;
    notifyListeners();

    _profile = await _localDataSource.getProfile();
    _transactions = await _localDataSource.getRecurringTransactions();
    _logs = await _localDataSource.getRecentDailyLogs(days: 30);
    final selectedGoal = await _localDataSource.getSelectedGoal();
    _goalId = (selectedGoal['goalId'] ?? '').trim();
    _goalName = (selectedGoal['goalName'] ?? '').trim();
    if (_goalName.isEmpty) {
      _goalName = 'Finansal Hedef';
    }

    _rebuildProjection(
      profile: _profile,
      transactions: _transactions,
      logs: _logs,
    );

    _aiInsightOverride = null;

    _isLoading = false;
    notifyListeners();
  }

  void _rebuildProjection({
    required ProfileModel? profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> logs,
  }) {
    final baseAmount = _estimateBaseWealth(profile);
    _monthlySurplus = _estimateMonthlySurplus(
      profile: profile,
      transactions: transactions,
      logs: logs,
    );

    _allPoints = _buildProjectionCurve(
      startYear: _startYear,
      years: _projectionYears,
      baseAmount: baseAmount,
      monthlySurplus: _monthlySurplus,
    );

    _transactionImpacts = _buildTransactionImpacts(transactions, logs, profile);

    final startMillions = _allPoints.isNotEmpty
        ? _allPoints.first.amountMillions
        : 0;
    final goalMultiplier = _goalMultiplierFor(_goalId);
    final trendBoost = max(0, _monthlySurplus) * 24;
    final goalFromProfile = (profile?.initialBalance ?? 0) * goalMultiplier;
    final fallbackGoal = max(150000, max(goalFromProfile, trendBoost));
    final goalMillions = max(startMillions + 0.1, fallbackGoal / 1000000);
    _goalMillions = goalMillions.clamp(0.2, 20.0);
  }

  List<TransactionImpact> _buildTransactionImpacts(
    List<RecurringTransactionModel> transactions,
    List<DailyLogModel> logs,
    ProfileModel? profile,
  ) {
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

  double _estimateBaseWealth(ProfileModel? profile) {
    if (profile == null) return 50000;
    return max(0, profile.savingsPool + max(0, profile.currentBalance) * 0.25);
  }

  double _estimateMonthlySurplus({
    required ProfileModel? profile,
    required List<RecurringTransactionModel> transactions,
    required List<DailyLogModel> logs,
  }) {
    final recurringIncome = transactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final recurringExpense = transactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final dailyTransferAvg = logs.isEmpty
        ? 0.0
        : logs.fold<double>(0, (sum, l) => sum + l.transferredToSavings) /
              logs.length;

    final dailySpendAvg = logs.isEmpty
        ? (profile?.dailyLimit ?? 0) * 0.8
        : logs.fold<double>(0, (sum, l) => sum + l.spentAmount) / logs.length;

    final monthlyTransfers = dailyTransferAvg * 30;
    final monthlyVariableSpend = dailySpendAvg * 30;

    return recurringIncome -
        recurringExpense +
        monthlyTransfers -
        monthlyVariableSpend;
  }

  List<ProjectionPoint> _buildProjectionCurve({
    required int startYear,
    required int years,
    required double baseAmount,
    required double monthlySurplus,
  }) {
    final points = <ProjectionPoint>[];
    var total = max(0, baseAmount);

    for (var i = 0; i <= years; i++) {
      if (i > 0) {
        total = (total + (monthlySurplus * 12)) * (1 + _annualReturnRate);
        total = max(0, total);
      }

      points.add(ProjectionPoint(startYear + i, total / 1000000));
    }

    return points;
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

  String _formatCompactTl(double amount) {
    final sign = amount >= 0 ? '+' : '-';
    final absAmount = amount.abs();
    if (absAmount >= 1000000) {
      return '$sign${(absAmount / 1000000).toStringAsFixed(1)}M TL';
    }
    if (absAmount >= 1000) {
      return '$sign${(absAmount / 1000).toStringAsFixed(1)}K TL';
    }
    return '$sign${absAmount.toStringAsFixed(0)} TL';
  }
}
