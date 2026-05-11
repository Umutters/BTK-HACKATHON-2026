import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';
import '../datasources/mock_local_datasource.dart';

class QuestRepositoryImpl implements QuestRepository {
  final MockLocalDataSource _dataSource;

  const QuestRepositoryImpl(this._dataSource);

  @override
  Future<List<QuestEntity>> getDailyQuests() async {
    final models = await _dataSource.getDailyQuests();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> startQuest(String questId) => _dataSource.startQuest(questId);

  @override
  Future<void> completeQuest(String questId) =>
      _dataSource.completeQuest(questId);
}
