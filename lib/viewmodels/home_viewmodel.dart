import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/quest_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/complete_quest_usecase.dart';
import '../../domain/usecases/get_daily_quests_usecase.dart';
import '../../domain/usecases/get_user_progress_usecase.dart';
import '../../domain/usecases/start_quest_usecase.dart';
import '../data/datasources/local_datasource.dart';
import '../data/models/crisis_event_model.dart';
import '../data/models/daily_log_model.dart';
import '../data/models/recurring_transaction_model.dart';
import '../data/services/supabase_service.dart';

enum HomeViewState { initial, loading, loaded, error }

class HomeViewModel extends ChangeNotifier {
  final GetUserProgressUseCase _getUserProgressUseCase;
  final GetDailyQuestsUseCase _getDailyQuestsUseCase;
  final StartQuestUseCase _startQuestUseCase;
  final CompleteQuestUseCase _completeQuestUseCase;
  final LocalDataSource _localDataSource = LocalDataSource();

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
  }) : _getUserProgressUseCase = getUserProgressUseCase,
       _getDailyQuestsUseCase = getDailyQuestsUseCase,
       _startQuestUseCase = startQuestUseCase,
       _completeQuestUseCase = completeQuestUseCase;

  Future<void> initialize({bool force = false}) async {
    if (_state == HomeViewState.loading) return;
    if (!force && _state == HomeViewState.loaded) return;

    _state = HomeViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId != null) {
        try {
          await SupabaseService.instance.reconcileDailySavingsAndXp(
            userId: userId,
            lookbackDays: 30,
          );
        } catch (_) {
          // Reconcile best-effort; ekran açılışını bloklamasın.
        }
      } else {
        try {
          await _localDataSource.reconcileDailySavingsAndXp(lookbackDays: 30);
        } catch (_) {
          // Local reconcile best-effort.
        }
      }

      final results = await Future.wait([
        _getUserProgressUseCase(),
        _getDailyQuestsUseCase(),
        _localDataSource.getRecurringTransactions(),
      ]);

      _user = results[0] as UserEntity;
      _quests = results[1] as List<QuestEntity>;
      _setTransactions(results[2] as List<RecurringTransactionModel>);
      _currencyCode = await _localDataSource.getPreferredCurrency();

      final profile = userId == null
          ? null
          : await SupabaseService.instance.getProfile(userId);
      if (profile != null) {
        _currentBalance = profile.currentBalance;
        _savingsPool = await SupabaseService.instance.getSavingsTotal(
          userId!,
        );
      } else {
        _currentBalance = 0;
        _savingsPool = 0;
      }

      // Auto-apply any due recurring rules
      if (userId != null) {
        try {
          final delta = await SupabaseService.instance.applyDueRules(userId);
          if (delta != 0) {
            _currentBalance = (_currentBalance + delta).clamp(
              0.0,
              double.maxFinite,
            );
          }
        } catch (_) {
          // Best-effort: don't fail initialization if auto-apply errors
        }

        try {
          _crisisEvents = await SupabaseService.instance.getCrisisEvents(
            userId,
          );
        } catch (_) {
          _crisisEvents = [];
        }
      }

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
    final userId = SupabaseService.instance.currentUserId;
    final today = DateTime.now();
    List<DailyLogModel> logs;
    if (userId != null) {
      try {
        logs = await SupabaseService.instance.getRecentDailyLogs(
          userId,
          days: 1,
        );
      } catch (_) {
        logs = await _localDataSource.getRecentDailyLogs(days: 1);
      }
    } else {
      logs = await _localDataSource.getRecentDailyLogs(days: 1);
    }

    return logs
        .where(
          (l) =>
              l.date.year == today.year &&
              l.date.month == today.month &&
              l.date.day == today.day,
        )
        .fold<double>(0, (sum, l) => sum + l.transferredToSavings);
  }

  Future<void> refreshTransactions() async {
    final txns = await _localDataSource.getRecurringTransactions();
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
        final gainedXp = _user!.currentXp + quest.xpReward;
        var nextLevel = _user!.level;
        var nextXp = gainedXp;
        var nextMaxXp = _user!.maxXp;

        if (gainedXp >= _user!.maxXp) {
          nextLevel = _user!.level + 1;
          nextXp = 0;
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
            await SupabaseService.instance.updateProfile(userId, {
              'xp': nextXp,
              'level': nextLevel,
            });
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
