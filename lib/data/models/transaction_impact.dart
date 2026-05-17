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
