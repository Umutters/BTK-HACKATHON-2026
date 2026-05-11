import 'package:flutter/foundation.dart';

class ProjectionPoint {
  final int year;
  final double amountMillions;

  const ProjectionPoint(this.year, this.amountMillions);
}

class SimulationViewModel extends ChangeNotifier {
  static const int _startYear = 2026;
  static const int _endYear = 2045;
  static const double _ultimateGoalMillions = 20.0;

  // Full 20-year mock projection data (compound growth with early dip)
  static const List<ProjectionPoint> _allPoints = [
    ProjectionPoint(2026, 2.0),
    ProjectionPoint(2027, 1.75),
    ProjectionPoint(2028, 2.2),
    ProjectionPoint(2029, 2.9),
    ProjectionPoint(2030, 3.7),
    ProjectionPoint(2031, 4.4),
    ProjectionPoint(2032, 5.8),
    ProjectionPoint(2033, 7.1),
    ProjectionPoint(2034, 8.6),
    ProjectionPoint(2035, 10.2),
    ProjectionPoint(2036, 12.0),
    ProjectionPoint(2037, 14.1),
    ProjectionPoint(2038, 16.5),
    ProjectionPoint(2039, 19.2),
    ProjectionPoint(2040, 22.3),
    ProjectionPoint(2041, 25.8),
    ProjectionPoint(2042, 29.8),
    ProjectionPoint(2043, 34.5),
    ProjectionPoint(2044, 39.8),
    ProjectionPoint(2045, 46.0),
  ];

  // Default slider at ~31.6% → shows year 2032 and $5.8M
  double _sliderValue = 0.316;

  double get sliderValue => _sliderValue;
  int get startYear => _startYear;
  int get endYear => _endYear;

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
      if (pt.amountMillions >= _ultimateGoalMillions) return pt.year;
    }
    return _endYear;
  }

  String get aiInsight =>
      "At this rate, you'll reach your goal by $aiGoalYear.";

  void setSliderValue(double value) {
    _sliderValue = value.clamp(0.0, 1.0);
    notifyListeners();
  }
}
