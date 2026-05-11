import 'package:flutter/foundation.dart';

import '../../domain/entities/quest_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_daily_quests_usecase.dart';
import '../../domain/usecases/get_user_progress_usecase.dart';
import '../../domain/usecases/start_quest_usecase.dart';

enum HomeViewState { initial, loading, loaded, error }

class HomeViewModel extends ChangeNotifier {
  final GetUserProgressUseCase _getUserProgressUseCase;
  final GetDailyQuestsUseCase _getDailyQuestsUseCase;
  final StartQuestUseCase _startQuestUseCase;

  HomeViewState _state = HomeViewState.initial;
  UserEntity? _user;
  List<QuestEntity> _quests = [];
  String? _errorMessage;

  HomeViewState get state => _state;
  UserEntity? get user => _user;
  List<QuestEntity> get quests => _quests;
  String? get errorMessage => _errorMessage;

  int get completedQuestsCount =>
      _quests.where((q) => q.status == QuestStatus.completed).length;

  HomeViewModel({
    required GetUserProgressUseCase getUserProgressUseCase,
    required GetDailyQuestsUseCase getDailyQuestsUseCase,
    required StartQuestUseCase startQuestUseCase,
  }) : _getUserProgressUseCase = getUserProgressUseCase,
       _getDailyQuestsUseCase = getDailyQuestsUseCase,
       _startQuestUseCase = startQuestUseCase;

  Future<void> initialize() async {
    if (_state == HomeViewState.loaded) return;

    _state = HomeViewState.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getUserProgressUseCase(),
        _getDailyQuestsUseCase(),
      ]);

      _user = results[0] as UserEntity;
      _quests = results[1] as List<QuestEntity>;
      _state = HomeViewState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeViewState.error;
    }

    notifyListeners();
  }

  Future<void> startQuest(String questId) async {
    try {
      await _startQuestUseCase(questId);
      _quests = _quests.map((q) {
        if (q.id == questId) {
          return q.copyWith(status: QuestStatus.inProgress);
        }
        return q;
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
