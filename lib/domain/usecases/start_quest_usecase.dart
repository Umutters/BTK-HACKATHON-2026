import '../repositories/quest_repository.dart';

class StartQuestUseCase {
  final QuestRepository _repository;

  const StartQuestUseCase(this._repository);

  Future<void> call(String questId) => _repository.startQuest(questId);
}
