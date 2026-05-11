import '../models/quest_model.dart';
import '../models/user_model.dart';

class MockLocalDataSource {
  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const UserModel(
      id: 'user_01',
      name: 'FortuneFlow User',
      level: 12,
      currentXp: 12450,
      maxXp: 15000,
    );
  }

  Future<List<QuestModel>> getDailyQuests() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      QuestModel(
        id: 'quest_01',
        title: 'Save \$10',
        description: 'Transfer to Vault',
        xpReward: 500,
        status: 'notStarted',
        iconName: 'savings',
      ),
      QuestModel(
        id: 'quest_02',
        title: 'Analyze Portfolio',
        description: 'Review AI insights',
        xpReward: 300,
        status: 'notStarted',
        iconName: 'bar_chart',
      ),
    ];
  }

  Future<void> startQuest(String questId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> completeQuest(String questId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
