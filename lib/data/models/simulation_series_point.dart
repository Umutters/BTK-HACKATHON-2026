class SimulationSeriesPoint {
  final int monthIndex;
  final DateTime date;
  final double amountMillions;

  const SimulationSeriesPoint({
    required this.monthIndex,
    required this.date,
    required this.amountMillions,
  });
}
