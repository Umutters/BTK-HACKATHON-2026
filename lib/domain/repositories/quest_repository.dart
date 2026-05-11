import '../entities/quest_entity.dart';

abstract class QuestRepository {
  Future<List<QuestEntity>> getDailyQuests();
  Future<void> startQuest(String questId);
  Future<void> completeQuest(String questId);
}
