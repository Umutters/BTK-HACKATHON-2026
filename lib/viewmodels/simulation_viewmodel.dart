import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';
import '../data/datasources/supabase_datasource.dart';
import '../data/models/crisis_event_model.dart';
import '../data/models/crisis_marker.dart';
import '../data/models/daily_log_model.dart';
import '../data/models/decision_log_model.dart';
import '../data/models/profile_model.dart';
import '../data/models/projection_point.dart';
import '../data/models/projection_table_row.dart';
import '../data/models/recurring_transaction_model.dart';
import '../data/models/simulation_series_point.dart';
import '../data/models/transaction_impact.dart';
import '../data/repositories/simulation_repository.dart';
import '../data/services/financial_simulation_engine.dart';
import '../data/services/gemini_service.dart';

class SimulationViewModel extends ChangeNotifier {
  static const double _defaultAnnualReturnRate = 0.08;

  final GeminiService _geminiService;
  final DateTime Function() _now;
  final SimulationRepository _simulationRepository;
  final FinancialSimulationEngine _simulationEngine;

  late final int _startYear;
  late int _endYear;
  late int _routeYears;

  List<ProjectionPoint> _currentPoints = const [];
  List<ProjectionPoint> _optimizedPoints = const [];
  List<SimulationSeriesPoint> _currentSeries = const [];
  List<SimulationSeriesPoint> _optimizedSeries = const [];
  List<TransactionImpact> _transactionImpacts = const [];
  List<CrisisEventModel> _crisisEvents = const [];
  List<DecisionLogModel> _decisionLogs = const [];
  List<CrisisMarker> _crisisMarkers = const [];

  double _extraDailySavings = 0.0;
  double _annualReturnRateSlider = _defaultAnnualReturnRate;
  bool _isLoading = true;
  bool _isGeneratingAi = false;

  double _goalMillions = 0.0;
  double _monthlySurplus = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  double _monthlySavingsTransfer = 0.0;
  double _monthlyNetCashflow = 0.0;
  double _savingsRatePercent = 0.0;
  double _emergencyRunwayMonths = 0.0;
  double _safeMonthlyBudget = 0.0;
  double _avgDailyTransferred30 = 0.0;
  double _avgDailyTransferred7 = 0.0;

  String _goalName = 'Finansal Hedef';
  String _goalId = '';
  String _currencyCode = 'TRY';
  String? _aiInsightOverride;

  ProfileModel? _profile;
  List<RecurringTransactionModel> _transactions = const [];
  List<DailyLogModel> _logs = const [];

  SimulationViewModel({
    LocalDataSource? localDataSource,
    SupabaseDataSource? supabaseDataSource,
    GeminiService? geminiService,
    SimulationRepository? simulationRepository,
    FinancialSimulationEngine? simulationEngine,
    DateTime Function()? now,
  }) : _geminiService = geminiService ?? GeminiService(),
       _now = now ?? DateTime.now,
       _simulationRepository =
           simulationRepository ??
           SimulationRepository(
             localDataSource: localDataSource,
             supabaseDataSource: supabaseDataSource,
           ),
       _simulationEngine =
           simulationEngine ??
           FinancialSimulationEngine(now: now ?? DateTime.now) {
    _startYear = _now().year;
    _routeYears = 20;
    _endYear = _startYear + _routeYears;
    _bootstrap();
  }

  bool get isLoading => _isLoading;
  bool get isGeneratingAi => _isGeneratingAi;
  double get extraDailySavings => _extraDailySavings;
  double get annualReturnRateSlider => _annualReturnRateSlider;
  int get startYear => _startYear;
  int get endYear => _endYear;
  int get routeYears => _routeYears;
  int? get targetAge {
    final age = _profile?.age;
    return age == null ? null : age + _routeYears;
  }

  double get goalMillions => _goalMillions;
  String get goalName => _goalName;
  String get currencySymbol => _currencyCode == 'USD' ? r'$' : 'TL';
  double get monthlySurplus => _monthlySurplus;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  double get monthlySavingsTransfer => _monthlySavingsTransfer;
  double get monthlyNetCashflow => _monthlyNetCashflow;
  double get savingsRatePercent => _savingsRatePercent;
  double get emergencyRunwayMonths => _emergencyRunwayMonths;
  double get safeMonthlyBudget => _safeMonthlyBudget;
  double get avgDailyTransferred30 => _avgDailyTransferred30;
  double get avgDailyTransferred7 => _avgDailyTransferred7;
  List<TransactionImpact> get transactionImpacts => _transactionImpacts;
  List<CrisisEventModel> get crisisEvents => _crisisEvents;
  List<CrisisMarker> get crisisMarkers => _crisisMarkers;
  List<ProjectionPoint> get currentPoints => _currentPoints;
  List<ProjectionPoint> get optimizedPoints => _optimizedPoints;
  List<SimulationSeriesPoint> get currentSeries => _currentSeries;
  List<SimulationSeriesPoint> get optimizedSeries => _optimizedSeries;

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

  List<ProjectionPoint> get visiblePoints => _currentPoints;

  double get targetAmountMillions {
    if (_optimizedPoints.isEmpty) return 0;
    return _optimizedPoints.last.amountMillions;
  }

  int get aiGoalYear {
    for (final pt in _optimizedPoints) {
      if (pt.amountMillions >= _goalMillions) return pt.year;
    }
    return _endYear;
  }

  String get aiInsight => _aiInsightOverride ?? '';

  void setExtraDailySavings(double value) {
    _extraDailySavings = value.clamp(0, 500);
    _rebuildProjection();
    notifyListeners();
    unawaited(generateAiInsight());
  }

  void setAnnualReturnRate(double value) {
    _annualReturnRateSlider = value.clamp(0.05, 0.25);
    _rebuildProjection();
    notifyListeners();
    unawaited(generateAiInsight());
  }

  void setRetirementGoal(double millions) {
    _goalMillions = millions.clamp(0.1, 20.0);
    notifyListeners();
    unawaited(generateAiInsight());
  }

  void setProjectionHorizonYears(double years) {
    final nextYears = years.round().clamp(5, 30);
    if (nextYears == _routeYears) return;
    _routeYears = nextYears;
    _endYear = _startYear + _routeYears;
    _rebuildProjection();
    _aiInsightOverride = null;
    notifyListeners();
    unawaited(generateAiInsight());
  }

  Future<void> refresh() => _bootstrap();

  Future<void> generateAiInsight() async {
    if (_profile == null || _currentPoints.isEmpty) return;

    _isGeneratingAi = true;
    notifyListeners();

    final topDrivers = _transactionImpacts
        .take(3)
        .map(
          (e) =>
              '${e.category} (${e.type}): ${_formatCompactMoney(e.monthlyImpact)}/ay, ${e.sharePercent.toStringAsFixed(0)}%',
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

  Future<void> _bootstrap() async {
    _isLoading = true;
    notifyListeners();

    _profile = await _simulationRepository.getUserProfile();
    _transactions = await _simulationRepository.getRecurringTransactions();
    _logs = await _simulationRepository.getRecentLogs(days: 30);

    final groundedSignals = await _simulationRepository.getGroundedSignals();
    _crisisEvents = groundedSignals.crisisEvents;
    _decisionLogs = groundedSignals.decisionLogs;

    _currencyCode = await _simulationRepository.getPreferredCurrency();
    final selectedGoal = await _simulationRepository.getSelectedGoal();
    _goalId = (selectedGoal['goalId'] ?? '').trim();
    _goalName = (selectedGoal['goalName'] ?? '').trim();
    if (_goalName.isEmpty) {
      _goalName = 'Finansal Hedef';
    }

    _rebuildProjection();

    _aiInsightOverride = null;
    _isLoading = false;
    notifyListeners();

    unawaited(generateAiInsight());
  }

  void _rebuildProjection() {
    final computed = _simulationEngine.compute(
      profile: _profile,
      transactions: _transactions,
      logs: _logs,
      crisisEvents: _crisisEvents,
      decisionLogs: _decisionLogs,
      routeYears: _routeYears,
      extraDailySavings: _extraDailySavings,
      annualReturnRateSlider: _annualReturnRateSlider,
      defaultAnnualReturnRate: _defaultAnnualReturnRate,
      goalId: _goalId,
    );

    _monthlySurplus = computed.monthlySurplus;
    _monthlyIncome = computed.monthlyIncome;
    _monthlyExpense = computed.monthlyExpense;
    _monthlySavingsTransfer = computed.monthlySavingsTransfer;
    _monthlyNetCashflow = computed.monthlyNetCashflow;
    _savingsRatePercent = computed.savingsRatePercent;
    _emergencyRunwayMonths = computed.emergencyRunwayMonths;
    _safeMonthlyBudget = computed.safeMonthlyBudget;
    _avgDailyTransferred30 = computed.avgDailyTransferred30;
    _avgDailyTransferred7 = computed.avgDailyTransferred7;

    _currentPoints = computed.currentPoints;
    _optimizedPoints = computed.optimizedPoints;
    _currentSeries = computed.currentSeries;
    _optimizedSeries = computed.optimizedSeries;
    _crisisMarkers = computed.crisisMarkers;
    _transactionImpacts = computed.transactionImpacts;

    _goalMillions = computed.goalMillions;
  }

  String _formatCompactMoney(double amount) {
    final sign = amount >= 0 ? '+' : '-';
    final absAmount = amount.abs();
    if (absAmount >= 1000000) {
      return '$sign${(absAmount / 1000000).toStringAsFixed(1)}M $currencySymbol';
    }
    if (absAmount >= 1000) {
      return '$sign${(absAmount / 1000).toStringAsFixed(1)}K $currencySymbol';
    }
    return '$sign${absAmount.toStringAsFixed(0)} $currencySymbol';
  }
}
