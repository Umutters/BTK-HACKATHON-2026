import '../../domain/entities/user_entity.dart';

/// Supabase `profiles` tablosuna karşılık gelir.
class ProfileModel {
  final String id;
  final String userName;
  final int? age;
  final String gender;
  final double initialBalance;
  final double currentBalance;
  final double savingsPool;
  final int level;
  final int xp;
  final double dailyLimit;

  const ProfileModel({
    required this.id,
    required this.userName,
    required this.age,
    required this.gender,
    required this.initialBalance,
    required this.currentBalance,
    required this.savingsPool,
    required this.level,
    required this.xp,
    required this.dailyLimit,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] ?? '').toString(),
      userName: json['username'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? '',
      initialBalance:
          ((json['inital_balance'] ?? json['initial_balance']) as num?)
              ?.toDouble() ??
          0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      savingsPool: (json['savings_pool'] as num?)?.toDouble() ?? 0.0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['daily_limit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': userName,
    'age': age,
    'gender': gender,
    'inital_balance': initialBalance,
    'current_balance': currentBalance,
    'savings_pool': savingsPool,
    'level': level,
    'xp': xp,
    'daily_limit': dailyLimit,
  };

  UserEntity toEntity() => UserEntity(
    id: id,
    name: userName,
    level: level,
    currentXp: xp,
    maxXp: level * 1000,
  );
}
