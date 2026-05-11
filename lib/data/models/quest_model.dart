import '../../domain/entities/quest_entity.dart';

class QuestModel {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final String status;
  final String iconName;

  const QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.status,
    required this.iconName,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: json['xpReward'] as int,
      status: json['status'] as String,
      iconName: json['iconName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'xpReward': xpReward,
    'status': status,
    'iconName': iconName,
  };

  QuestEntity toEntity() => QuestEntity(
    id: id,
    title: title,
    description: description,
    xpReward: xpReward,
    status: _parseStatus(status),
    iconName: iconName,
  );

  static QuestStatus _parseStatus(String value) {
    switch (value) {
      case 'inProgress':
        return QuestStatus.inProgress;
      case 'completed':
        return QuestStatus.completed;
      default:
        return QuestStatus.notStarted;
    }
  }
}
