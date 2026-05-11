class UserEntity {
  final String id;
  final String name;
  final int level;
  final int currentXp;
  final int maxXp;

  const UserEntity({
    required this.id,
    required this.name,
    required this.level,
    required this.currentXp,
    required this.maxXp,
  });

  double get xpProgress => currentXp / maxXp;

  UserEntity copyWith({
    String? id,
    String? name,
    int? level,
    int? currentXp,
    int? maxXp,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
    );
  }
}
