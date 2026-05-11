/// Supabase `decisions_log` tablosuna karşılık gelir.
class DecisionLogModel {
  final String id;
  final String userId;
  final String actionTaken;
  final int xpGained;

  const DecisionLogModel({
    required this.id,
    required this.userId,
    required this.actionTaken,
    required this.xpGained,
  });

  factory DecisionLogModel.fromJson(Map<String, dynamic> json) {
    return DecisionLogModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      actionTaken: json['action_taken'] as String? ?? '',
      xpGained: (json['xp_gained'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'user_id': userId,
    'action_taken': actionTaken,
    'xp_gained': xpGained,
  };
}
