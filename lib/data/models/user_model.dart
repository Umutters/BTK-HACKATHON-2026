import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final int level;
  final int currentXp;
  final int maxXp;

  const UserModel({
    required this.id,
    required this.name,
    required this.level,
    required this.currentXp,
    required this.maxXp,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      currentXp: json['currentXp'] as int,
      maxXp: json['maxXp'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'currentXp': currentXp,
    'maxXp': maxXp,
  };

  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    level: level,
    currentXp: currentXp,
    maxXp: maxXp,
  );
}
