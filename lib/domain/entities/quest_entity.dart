enum QuestStatus { notStarted, inProgress, completed }

class QuestEntity {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final QuestStatus status;
  final String iconName;

  const QuestEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.status,
    required this.iconName,
  });

  QuestEntity copyWith({
    String? id,
    String? title,
    String? description,
    int? xpReward,
    QuestStatus? status,
    String? iconName,
  }) {
    return QuestEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      status: status ?? this.status,
      iconName: iconName ?? this.iconName,
    );
  }
}
