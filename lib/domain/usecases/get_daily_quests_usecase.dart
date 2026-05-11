import '../entities/quest_entity.dart';
import '../repositories/quest_repository.dart';

class GetDailyQuestsUseCase {
  final QuestRepository _repository;

  const GetDailyQuestsUseCase(this._repository);

  Future<List<QuestEntity>> call() => _repository.getDailyQuests();
}
