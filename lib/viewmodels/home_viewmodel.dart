import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/quest_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/complete_quest_usecase.dart';
import '../../domain/usecases/get_daily_quests_usecase.dart';
import '../../domain/usecases/get_user_progress_usecase.dart';
import '../../domain/usecases/start_quest_usecase.dart';
import '../data/models/crisis_event_model.dart';
import '../data/models/recurring_transaction_model.dart';
import '../data/repositories/home_repository.dart';
import '../data/services/supabase_service.dart';

enum HomeViewState { initial, loading, loaded, error }

class HomeViewModel extends ChangeNotifier {
  final GetUserProgressUseCase _getUserProgressUseCase;
  final GetDailyQuestsUseCase _getDailyQuestsUseCase;
  final StartQuestUseCase _startQuestUseCase;
  final CompleteQuestUseCase _completeQuestUseCase;
  final HomeRepository _homeRepository;

  HomeViewState _state = HomeViewState.initial;
  UserEntity? _user;
  double _currentBalance = 0;
  double _savingsPool = 0;
  List<RecurringTransactionModel> _transactions = [];
  List<QuestEntity> _quests = [];
  List<CrisisEventModel> _crisisEvents = [];
  String? _errorMessage;
  String _currencyCode = 'TRY';

  HomeViewState get state => _state;
  UserEntity? get user => _user;
  double get currentBalance => _currentBalance;
  double get savingsPool => _savingsPool;
  List<RecurringTransactionModel> get allTransactions =>
      List.unmodifiable(_transactions);
  List<RecurringTransactionModel> get recentTransactions =>
      _transactions.take(5).toList(growable: false);
  List<QuestEntity> get quests => _quests;
  List<CrisisEventModel> get crisisEvents => List.unmodifiable(_crisisEvents);
  String? get errorMessage => _errorMessage;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencyCode == 'USD' ? r'$' : 'TL';

  int get completedQuestsCount =>
      _quests.where((q) => q.status == QuestStatus.completed).length;

  HomeViewModel({
    required GetUserProgressUseCase getUserProgressUseCase,
    required GetDailyQuestsUseCase getDailyQuestsUseCase,
    required StartQuestUseCase startQuestUseCase,
    required CompleteQuestUseCase completeQuestUseCase,
    HomeRepository? homeRepository,
  }) : _getUserProgressUseCase = getUserProgressUseCase,
       _getDailyQuestsUseCase = getDailyQuestsUseCase,
       _startQuestUseCase = startQuestUseCase,
       _completeQuestUseCase = completeQuestUseCase,
       _homeRepository = homeRepository ?? HomeRepository();

  Future<void> initialize({bool force = false}) async {
    if (_state == HomeViewState.loading) return;
    if (!force && _state == HomeViewState.loaded) return;

    _state = HomeViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _homeRepository.reconcileDailySavingsAndXp(lookbackDays: 30);

      final results = await Future.wait([
        _getUserProgressUseCase(),
        _getDailyQuestsUseCase(),
        _homeRepository.getRecurringTransactions(),
      ]);

      _user = results[0] as UserEntity;
      _quests = results[1] as List<QuestEntity>;
      _setTransactions(results[2] as List<RecurringTransactionModel>);
      _currencyCode = await _homeRepository.getPreferredCurrency();

      final financeSnapshot = await _homeRepository.getFinanceSnapshot();
      _currentBalance = financeSnapshot.currentBalance;
      _savingsPool = financeSnapshot.savingsPool;
      _crisisEvents = financeSnapshot.crisisEvents;

      _state = HomeViewState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeViewState.error;
    }

    notifyListeners();
  }

  Future<void> refresh() => initialize(force: true);

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

  void applyTransactionDelta(double delta) {
    _currentBalance = (_currentBalance + delta)
        .clamp(0.0, double.infinity)
        .toDouble();
    notifyListeners();
    unawaited(refreshTransactions());
  }

  Future<void> processSavingsTransfer(double transferredAmount) async {
    if (transferredAmount <= 0) return;

    QuestEntity? q2;
    for (final quest in _quests) {
      if (quest.id == 'q2') {
        q2 = quest;
        break;
      }
    }

    if (q2 == null || q2.status == QuestStatus.completed) {
      return;
    }

    final todayTransferred = await _getTodayTransferredToSavings();
    if (todayTransferred >= 50) {
      await completeQuest('q2');
    }
  }

  Future<double> _getTodayTransferredToSavings() async {
    return _homeRepository.getTodayTransferredToSavings();
  }

  Future<void> refreshTransactions() async {
    final txns = await _homeRepository.getRecurringTransactions();
    _setTransactions(txns);
    notifyListeners();
  }

  void _setTransactions(List<RecurringTransactionModel> source) {
    final userId = _user?.id;
    var filtered = source;
    if (userId != null && userId.isNotEmpty) {
      final scoped = source.where((t) => t.userId == userId).toList();
      if (scoped.isNotEmpty) {
        filtered = scoped;
      }
    }

    filtered.sort((a, b) {
      final bKey = int.tryParse(b.id) ?? 0;
      final aKey = int.tryParse(a.id) ?? 0;
      return bKey.compareTo(aKey);
    });
    _transactions = filtered;
  }

  Future<void> completeQuest(String questId) async {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      if (quest.status == QuestStatus.completed) {
        return;
      }

      await _completeQuestUseCase(questId);

      // Lokal UI güncellemesi
      _quests = _quests.map((q) {
        if (q.id == questId) return q.copyWith(status: QuestStatus.completed);
        return q;
      }).toList();

      // XP güncelleme
      if (_user != null) {
        var nextLevel = _user!.level;
        var nextXp = _user!.currentXp + quest.xpReward;
        var nextMaxXp = _user!.maxXp;

        while (nextXp >= nextMaxXp) {
          nextXp -= nextMaxXp;
          nextLevel += 1;
          nextMaxXp = nextLevel * 1000;
        }

        _user = UserEntity(
          id: _user!.id,
          name: _user!.name,
          level: nextLevel,
          currentXp: nextXp,
          maxXp: nextMaxXp,
        );

        // Supabase'e yaz
        final userId = SupabaseService.instance.currentUserId;
        if (userId != null) {
          try {
            await _homeRepository.updateXpAndLevel(
              userId: userId,
              xp: nextXp,
              level: nextLevel,
            );
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
