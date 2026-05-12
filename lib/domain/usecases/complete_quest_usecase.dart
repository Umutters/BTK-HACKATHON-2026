import '../repositories/quest_repository.dart';

class CompleteQuestUseCase {
  final QuestRepository _repository;

  const CompleteQuestUseCase(this._repository);

  Future<void> call(String questId) => _repository.completeQuest(questId);
}
