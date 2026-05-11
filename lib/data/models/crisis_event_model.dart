/// Supabase `crisis_events` tablosuna karşılık gelir.
class CrisisEventModel {
  final String id;
  final String userId;
  final String eventName;
  final double amount;
  final String resolutionStrategy; // 'pool' veya 'budget'

  const CrisisEventModel({
    required this.id,
    required this.userId,
    required this.eventName,
    required this.amount,
    required this.resolutionStrategy,
  });

  factory CrisisEventModel.fromJson(Map<String, dynamic> json) {
    return CrisisEventModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      eventName: json['event_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      resolutionStrategy: json['resolution_strategy'] as String? ?? 'budget',
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'user_id': userId,
    'event_name': eventName,
    'amount': amount,
    'resolution_strategy': resolutionStrategy,
  };
}
