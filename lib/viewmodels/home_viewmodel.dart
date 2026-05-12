import 'package:flutter/foundation.dart';

import '../../domain/entities/quest_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/complete_quest_usecase.dart';
import '../../domain/usecases/get_daily_quests_usecase.dart';
import '../../domain/usecases/get_user_progress_usecase.dart';
import '../../domain/usecases/start_quest_usecase.dart';
import '../data/services/supabase_service.dart';

enum HomeViewState { initial, loading, loaded, error }

class HomeViewModel extends ChangeNotifier {
  final GetUserProgressUseCase _getUserProgressUseCase;
  final GetDailyQuestsUseCase _getDailyQuestsUseCase;
  final StartQuestUseCase _startQuestUseCase;
  final CompleteQuestUseCase _completeQuestUseCase;

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
    required CompleteQuestUseCase completeQuestUseCase,
  }) : _getUserProgressUseCase = getUserProgressUseCase,
       _getDailyQuestsUseCase = getDailyQuestsUseCase,
       _startQuestUseCase = startQuestUseCase,
       _completeQuestUseCase = completeQuestUseCase;

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

  Future<void> completeQuest(String questId) async {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      await _completeQuestUseCase(questId);

      // Lokal UI güncellemesi
      _quests = _quests.map((q) {
        if (q.id == questId) return q.copyWith(status: QuestStatus.completed);
        return q;
      }).toList();

      // XP güncelleme
      if (_user != null) {
        final newXp = _user!.currentXp + quest.xpReward;
        _user = UserEntity(
          id: _user!.id,
          name: _user!.name,
          level: _user!.level,
          currentXp: newXp,
          maxXp: _user!.maxXp,
        );

        // Supabase'e yaz
        final userId = SupabaseService.instance.currentUserId;
        if (userId != null) {
          try {
            await SupabaseService.instance.updateXp(userId, newXp);
          } catch (e) {
            debugPrint('XP Supabase güncellemesi başarısız: $e');
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
