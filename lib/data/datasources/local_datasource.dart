import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_log_model.dart';
import '../models/profile_model.dart';
import '../models/quest_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/user_model.dart';

/// SharedPreferences tabanlı yerel veri kaynağı.
/// Profil, recurring transactions, daily logs ve quest durumları burada saklanır.
class LocalDataSource {
  static const _profileKey = 'ldb_profile';
  static const _transactionsKey = 'ldb_transactions';
  static const _rulesKey = 'ldb_recurring_rules';
  static const _dailyLogsKey = 'ldb_daily_logs';
  static const _questStatusKey = 'ldb_quest_status';
  static const _onboardingDoneKey = 'ldb_onboarding_done';
  static const _goalIdKey = 'ldb_goal_id';
  static const _goalNameKey = 'ldb_goal_name';

  /// main.dart'ta önceden başlatılır.
  static SharedPreferences? sharedPrefs;

  Future<SharedPreferences> get _prefs async =>
      sharedPrefs ??= await SharedPreferences.getInstance();

  // ─── Quests (sabit tanım, durum persist edilir) ───────────────────────────

  static const List<QuestModel> _defaultQuests = [
    QuestModel(
      id: 'q1',
      title: 'Günlük Limit Koru',
      description: 'Bugün harcama limitini aşma',
      xpReward: 200,
      status: 'notStarted',
      iconName: 'limit',
    ),
    QuestModel(
      id: 'q2',
      title: 'Tasarrufa Aktar',
      description: 'Birikime en az 50₺ aktar',
      xpReward: 300,
      status: 'notStarted',
      iconName: 'savings',
    ),
    QuestModel(
      id: 'q3',
      title: 'Kâhine Sor',
      description: 'AI danışmanına bir soru sor',
      xpReward: 100,
      status: 'notStarted',
      iconName: 'oracle',
    ),
  ];

  Future<List<QuestModel>> getDailyQuests() async {
    final prefs = await _prefs;
    final statusJson = prefs.getString(_questStatusKey);
    if (statusJson == null) return _defaultQuests;
    final statusMap = jsonDecode(statusJson) as Map<String, dynamic>;
    return _defaultQuests.map((q) {
      final status = statusMap[q.id] as String? ?? 'notStarted';
      return QuestModel(
        id: q.id,
        title: q.title,
        description: q.description,
        xpReward: q.xpReward,
        status: status,
        iconName: q.iconName,
      );
    }).toList();
  }

  Future<void> startQuest(String questId) =>
      _setQuestStatus(questId, 'inProgress');

  Future<void> completeQuest(String questId) =>
      _setQuestStatus(questId, 'completed');

  Future<void> _setQuestStatus(String questId, String status) async {
    final prefs = await _prefs;
    final statusJson = prefs.getString(_questStatusKey);
    final statusMap = statusJson == null
        ? <String, dynamic>{}
        : jsonDecode(statusJson) as Map<String, dynamic>;
    statusMap[questId] = status;
    await prefs.setString(_questStatusKey, jsonEncode(statusMap));
  }

  // ─── UserModel (UserRepositoryImpl uyumluluğu için) ───────────────────────

  Future<UserModel> getUserProfile() async {
    final profile = await getProfile();
    if (profile == null) {
      return const UserModel(
        id: 'local',
        name: 'FortuneFlow',
        level: 1,
        currentXp: 0,
        maxXp: 1000,
      );
    }
    return UserModel(
      id: profile.id,
      name: profile.userName.isEmpty ? 'FortuneFlow' : profile.userName,
      level: profile.level,
      currentXp: profile.xp,
      maxXp: profile.level * 1000,
    );
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<ProfileModel?> getProfile() async {
    final prefs = await _prefs;
    final json = prefs.getString(_profileKey);
    if (json == null) return null;
    return ProfileModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final prefs = await _prefs;
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<bool> hasProfile() async {
    final prefs = await _prefs;
    return prefs.containsKey(_profileKey);
  }

  Future<void> setOnboardingDone(bool done) async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingDoneKey, done);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  Future<void> saveSelectedGoal({
    required String goalId,
    required String goalName,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_goalIdKey, goalId);
    await prefs.setString(_goalNameKey, goalName);
  }

  Future<Map<String, String>> getSelectedGoal() async {
    final prefs = await _prefs;
    return {
      'goalId': prefs.getString(_goalIdKey) ?? '',
      'goalName': prefs.getString(_goalNameKey) ?? '',
    };
  }

  // ─── Recurring Transactions ───────────────────────────────────────────────

  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    final prefs = await _prefs;
    final json = prefs.getString(_transactionsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map(
          (e) => RecurringTransactionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveRecurringTransactions(
    List<RecurringTransactionModel> txns,
  ) async {
    final prefs = await _prefs;
    await prefs.setString(
      _transactionsKey,
      jsonEncode(
        txns
            .map(
              (t) => {
                'Id': t.id,
                'User_id': t.userId,
                'Type': t.type,
                'Category': t.category,
                'Amount': t.amount,
              },
            )
            .toList(),
      ),
    );
  }

  Future<void> addRecurringTransaction(RecurringTransactionModel txn) async {
    final list = await getRecurringTransactions();
    list.add(txn);
    await saveRecurringTransactions(list);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final list = await getRecurringTransactions();
    list.removeWhere((t) => t.id == id);
    await saveRecurringTransactions(list);
  }

  // ─── Recurring Rules ──────────────────────────────────────────────────────

  Future<List<RecurringRuleModel>> getRecurringRules() async {
    final prefs = await _prefs;
    final json = prefs.getString(_rulesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => RecurringRuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRecurringRules(List<RecurringRuleModel> rules) async {
    final prefs = await _prefs;
    await prefs.setString(
      _rulesKey,
      jsonEncode(rules.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> addRecurringRule(RecurringRuleModel rule) async {
    final list = await getRecurringRules();
    list.add(rule);
    await saveRecurringRules(list);
  }

  Future<void> updateRecurringRule(RecurringRuleModel updated) async {
    final list = await getRecurringRules();
    final idx = list.indexWhere((r) => r.id == updated.id);
    if (idx >= 0) list[idx] = updated;
    await saveRecurringRules(list);
  }

  Future<void> deleteRecurringRule(String id) async {
    final list = await getRecurringRules();
    list.removeWhere((r) => r.id == id);
    await saveRecurringRules(list);
  }

  // ─── Daily Logs ───────────────────────────────────────────────────────────

  Future<List<DailyLogModel>> getRecentDailyLogs({int days = 7}) async {
    final prefs = await _prefs;
    final json = prefs.getString(_dailyLogsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    final all = list
        .map((e) => DailyLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final since = DateTime.now().subtract(Duration(days: days));
    return all
      ..retainWhere((l) => l.date.isAfter(since))
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> logDailySpending({
    required double spentAmount,
    required double transferredToSavings,
  }) async {
    final prefs = await _prefs;
    final json = prefs.getString(_dailyLogsKey);
    final list = json == null ? <dynamic>[] : jsonDecode(json) as List<dynamic>;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    Map<String, dynamic>? existing;
    for (final entry in list) {
      final map = entry as Map<String, dynamic>;
      if (map['date'] == today) {
        existing = map;
        break;
      }
    }

    final mergedSpent =
        ((existing?['spent_amount'] as num?)?.toDouble() ?? 0) + spentAmount;
    final mergedTransferred =
        ((existing?['transferred_to_savings'] as num?)?.toDouble() ?? 0) +
        transferredToSavings;

    list.removeWhere((e) => (e as Map<String, dynamic>)['date'] == today);
    list.add({
      'id': today,
      'user_id': 'local',
      'date': today,
      'spent_amount': mergedSpent,
      'transferred_to_savings': mergedTransferred,
    });
    // Son 30 günü tut
    if (list.length > 30) list.removeRange(0, list.length - 30);
    await prefs.setString(_dailyLogsKey, jsonEncode(list));
  }

  // ─── Temizle (logout / reset) ─────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_profileKey),
      prefs.remove(_transactionsKey),
      prefs.remove(_rulesKey),
      prefs.remove(_dailyLogsKey),
      prefs.remove(_questStatusKey),
      prefs.remove(_onboardingDoneKey),
      prefs.remove(_goalIdKey),
      prefs.remove(_goalNameKey),
    ]);
  }
}
