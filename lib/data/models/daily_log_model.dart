/// Supabase `daily_logs` tablosuna karşılık gelir.
class DailyLogModel {
  final String id;
  final String userId;
  final DateTime date;
  final double spentAmount;
  final double transferredToSavings;

  const DailyLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.spentAmount,
    required this.transferredToSavings,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
      transferredToSavings:
          (json['transferred_to_savings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
