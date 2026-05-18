import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crisis_event_model.dart';
import '../models/daily_log_model.dart';
import '../models/decision_log_model.dart';
import '../models/profile_model.dart';
import '../models/quest_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/recurring_transaction_model.dart';

/// Supabase istemcisine merkezi erişim sağlar.
/// Supabase.initialize() main.dart'ta çağrıldıktan sonra kullanılabilir.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const List<Map<String, dynamic>> _defaultDailyQuests = [
    {
      'id': 'q1',
      'title': 'Günlük Limit Koru',
      'description': 'Bugün harcama limitini aşma',
      'xp_reward': 200,
      'icon_name': 'limit',
    },
    {
      'id': 'q2',
      'title': 'Tasarrufa Aktar',
      'description': 'Birikime en az 50₺ aktar',
      'xp_reward': 300,
      'icon_name': 'savings',
    },
    {
      'id': 'q3',
      'title': 'Kâhine Sor',
      'description': 'AI danışmanına bir soru sor',
      'xp_reward': 100,
      'icon_name': 'oracle',
    },
  ];

  // ─── Auth ─────────────────────────────────────────────────────────────────

  bool get isSignedIn => _client.auth.currentUser != null;

  /// Oturum açık değilse anonim oturum açar.
  Future<void> ensureSignedIn() async {
    if (!isSignedIn) {
      await _client.auth.signInAnonymously();
    }
  }

  // ─── Profiles ────────────────────────────────────────────────────────────────

  /// Yeni profil satırı oluşturur (onboarding sonu).
  Future<void> insertProfile(ProfileModel profile) {
    final payload = Map<String, dynamic>.from(profile.toJson())..remove('id');

    // users.id bigint identity olduğu için auth UUID'yi ayrı kolonda tut.
    if (currentUserId != null) {
      payload['auth_user_id'] = currentUserId;
    }

    return _client.from('users').insert(payload);
  }

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle();
      if (data != null) return ProfileModel.fromJson(data);
    } on PostgrestException {
      // auth_user_id henüz eklenmediyse legacy id yoluna düş.
    }

    final numericId = int.tryParse(userId);
    if (numericId == null) return null;

    final legacy = await _client
        .from('users')
        .select()
        .eq('id', numericId)
        .maybeSingle();
    if (legacy == null) return null;
    return ProfileModel.fromJson(legacy);
  }

  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final res = await _client
          .from('users')
          .update(updates)
          .eq('auth_user_id', userId)
          .select('id')
          .maybeSingle();
      if (res != null) return;
    } on PostgrestException {
      // auth_user_id kolonu yoksa legacy id ile güncellemeyi dene.
    }

    final numericId = int.tryParse(userId);
    if (numericId == null) return;
    await _client.from('users').update(updates).eq('id', numericId);
  }

  Future<void> updateXp(String userId, int xp) =>
      updateProfile(userId, {'xp': xp});

  Future<void> updateBalance(String userId, double balance) =>
      updateProfile(userId, {'current_balance': balance});

  Future<void> addToSavingsPool(String userId, double amount) async {
    // ESKI MANTIK KALDIRILAN - Birikim artık calculated field:
    // savingsPool = SUM(daily_logs.transferred_to_savings)
    // Crisis işlemleri daily_logs'ta negatif transfer olarak kaydedilir
    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final existing = await _client
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();

      final currentTransferred =
          ((existing?['transferred_to_savings'] as num?)?.toDouble() ?? 0);
      final newTransferred = currentTransferred + amount;

      if (existing == null) {
        await _client.from('daily_logs').insert({
          'user_id': userId,
          'date': today,
          'spent_amount': 0,
          'transferred_to_savings': newTransferred,
        });
      } else {
        await _client
            .from('daily_logs')
            .update({'transferred_to_savings': newTransferred})
            .eq('user_id', userId)
            .eq('date', today);
      }
    } on PostgrestException {
      // Legacy user fallback
      final legacyUserId = await _resolveLegacyUserId(userId);
      if (legacyUserId != null) {
        final existing = await _client
            .from('daily_logs')
            .select()
            .eq('user_id', legacyUserId)
            .eq('date', today)
            .maybeSingle();

        final currentTransferred =
            ((existing?['transferred_to_savings'] as num?)?.toDouble() ?? 0);
        final newTransferred = currentTransferred + amount;

        if (existing == null) {
          await _client.from('daily_logs').insert({
            'user_id': legacyUserId,
            'date': today,
            'spent_amount': 0,
            'transferred_to_savings': newTransferred,
          });
        } else {
          await _client
              .from('daily_logs')
              .update({'transferred_to_savings': newTransferred})
              .eq('user_id', legacyUserId)
              .eq('date', today);
        }
      }
    }
  }

  // ─── Recurring Transactions ───────────────────────────────────────────────

  Future<List<RecurringTransactionModel>> getRecurringTransactions(
    String userId,
  ) async {
    final data = await _client
        .from('recurring_transactions')
        .select()
        .eq('User_id', userId);
    return (data as List)
        .map(
          (e) => RecurringTransactionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  // ─── Günlük görevler ─────────────────────────────────────────────────────

  Future<List<QuestModel>> getOrCreateDailyQuests(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await _client
        .from('daily_quests')
        .select()
        .eq('user_id', userId)
        .eq('quest_date', today)
        .order('id');

    final existingList = (existing as List)
        .map((e) => QuestModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (existingList.isNotEmpty) return existingList;

    final insertPayload = _defaultDailyQuests
        .map(
          (q) => {
            'id': q['id'],
            'user_id': userId,
            'quest_date': today,
            'title': q['title'],
            'description': q['description'],
            'xp_reward': q['xp_reward'],
            'status': 'notStarted',
            'icon_name': q['icon_name'],
          },
        )
        .toList();

    try {
      await _client.from('daily_quests').insert(insertPayload);
    } on PostgrestException {
      // Paralel bir istek aynı kayıtları eklemiş olabilir; aşağıda tekrar okuyacağız.
    }

    final created = await _client
        .from('daily_quests')
        .select()
        .eq('user_id', userId)
        .eq('quest_date', today)
        .order('id');

    return (created as List)
        .map((e) => QuestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> startDailyQuest(String userId, String questId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _client
        .from('daily_quests')
        .update({'status': 'inProgress'})
        .eq('user_id', userId)
        .eq('quest_date', today)
        .eq('id', questId);
  }

  Future<void> completeDailyQuest(String userId, String questId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _client
        .from('daily_quests')
        .update({'status': 'completed'})
        .eq('user_id', userId)
        .eq('quest_date', today)
        .eq('id', questId);
  }

  // ─── Daily Logs ───────────────────────────────────────────────────────────

  Future<List<DailyLogModel>> getRecentDailyLogs(
    String userId, {
    int days = 7,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final sinceDate = since.toIso8601String().substring(0, 10);

    try {
      final data = await _client
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', sinceDate)
          .order('date', ascending: false);
      return (data as List)
          .map((e) => DailyLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      final legacyUserId = await _resolveLegacyUserId(userId);
      if (legacyUserId == null) return const [];

      final data = await _client
          .from('daily_logs')
          .select()
          .eq('user_id', legacyUserId)
          .gte('date', sinceDate)
          .order('date', ascending: false);
      return (data as List)
          .map((e) => DailyLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  /// Havuz toplamı = SUM(daily_logs.transferred_to_savings)
  Future<double> getSavingsTotal(String userId) async {
    final profile = await getProfile(userId);
    if (profile == null) return 0.0;

    try {
      final data = await _client
          .from('daily_logs')
          .select('transferred_to_savings')
          .eq('user_id', userId);

      final transferred =
          (data as List?)?.fold<double>(
            0,
            (sum, row) =>
                sum +
                ((row['transferred_to_savings'] as num?)?.toDouble() ?? 0),
          ) ??
          0;

      return transferred;
    } on PostgrestException {
      final legacyUserId = await _resolveLegacyUserId(userId);
      if (legacyUserId == null) return 0.0;

      try {
        final data = await _client
            .from('daily_logs')
            .select('transferred_to_savings')
            .eq('user_id', legacyUserId);

        final transferred =
            (data as List?)?.fold<double>(
              0,
              (sum, row) =>
                  sum +
                  ((row['transferred_to_savings'] as num?)?.toDouble() ?? 0),
            ) ??
            0;

        return transferred;
      } on PostgrestException {
        return 0.0;
      }
    }
  }

  Future<void> insertDailyLog({
    required String userId,
    required double spentAmount,
    required double transferredToSavings,
    double? dailyLimit,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final existing = await _client
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();

      final mergedSpent =
          ((existing?['spent_amount'] as num?)?.toDouble() ?? 0) + spentAmount;
      final mergedTransferred =
          ((existing?['transferred_to_savings'] as num?)?.toDouble() ?? 0) +
          transferredToSavings;
      final resolvedTransferred = dailyLimit == null
          ? mergedTransferred
          : max(0.0, dailyLimit - mergedSpent);

      if (existing == null) {
        await _client.from('daily_logs').insert({
          'user_id': userId,
          'date': today,
          'spent_amount': mergedSpent,
          'transferred_to_savings': resolvedTransferred,
        });
      } else {
        await _client
            .from('daily_logs')
            .update({
              'spent_amount': mergedSpent,
              'transferred_to_savings': resolvedTransferred,
            })
            .eq('user_id', userId)
            .eq('date', today);
      }
      return;
    } on PostgrestException {
      // Legacy şemada user_id bigint olabilir; aşağıda fallback var.
    }

    final legacyUserId = await _resolveLegacyUserId(userId);
    if (legacyUserId == null) {
      throw Exception('daily_logs için legacy user_id çözümlenemedi: $userId');
    }

    final existing = await _client
        .from('daily_logs')
        .select()
        .eq('user_id', legacyUserId)
        .eq('date', today)
        .maybeSingle();

    final mergedSpent =
        ((existing?['spent_amount'] as num?)?.toDouble() ?? 0) + spentAmount;
    final mergedTransferred =
        ((existing?['transferred_to_savings'] as num?)?.toDouble() ?? 0) +
        transferredToSavings;
    final resolvedTransferred = dailyLimit == null
        ? mergedTransferred
        : max(0.0, dailyLimit - mergedSpent);

    if (existing == null) {
      await _client.from('daily_logs').insert({
        'user_id': legacyUserId,
        'date': today,
        'spent_amount': mergedSpent,
        'transferred_to_savings': resolvedTransferred,
      });
    } else {
      await _client
          .from('daily_logs')
          .update({
            'spent_amount': mergedSpent,
            'transferred_to_savings': resolvedTransferred,
          })
          .eq('user_id', legacyUserId)
          .eq('date', today);
    }
  }

  Future<void> setDailyTransferredForDate({
    required String userId,
    required String date,
    required double transferredToSavings,
  }) async {
    try {
      await _client
          .from('daily_logs')
          .update({'transferred_to_savings': transferredToSavings})
          .eq('user_id', userId)
          .eq('date', date);
      return;
    } on PostgrestException {
      // Legacy şema için fallback aşağıda.
    }

    final legacyUserId = await _resolveLegacyUserId(userId);
    if (legacyUserId == null) return;
    await _client
        .from('daily_logs')
        .update({'transferred_to_savings': transferredToSavings})
        .eq('user_id', legacyUserId)
        .eq('date', date);
  }

  Future<void> reconcileDailySavingsAndXp({
    required String userId,
    int lookbackDays = 30,
    int disciplineXp = 10,
  }) async {
    final reconciledWithColumns = await _reconcileDailyUsingLogColumns(
      userId: userId,
      lookbackDays: lookbackDays,
      disciplineXp: disciplineXp,
    );
    if (reconciledWithColumns) {
      return;
    }

    final profile = await getProfile(userId);
    if (profile == null || profile.dailyLimit <= 0) return;

    final logs = await getRecentDailyLogs(userId, days: lookbackDays);
    if (logs.isEmpty) return;

    final processedDates = await _getProcessedReconcileDates(userId);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    int xpDelta = 0;
    final actions = <String>[];

    for (final log in logs) {
      final dateKey = log.date.toIso8601String().substring(0, 10);
      if (dateKey == today || processedDates.contains(dateKey)) {
        continue;
      }

      final expectedTransfer = max(0.0, profile.dailyLimit - log.spentAmount);
      if ((log.transferredToSavings - expectedTransfer).abs() > 0.01) {
        await setDailyTransferredForDate(
          userId: userId,
          date: dateKey,
          transferredToSavings: expectedTransfer,
        );
      }

      if (log.spentAmount <= profile.dailyLimit) {
        xpDelta += disciplineXp;
      }

      actions.add(
        'AUTO_DAILY_RECONCILE:$dateKey:spent=${log.spentAmount.toStringAsFixed(2)}:transfer=${expectedTransfer.toStringAsFixed(2)}:xp=${log.spentAmount <= profile.dailyLimit ? disciplineXp : 0}',
      );
    }

    if (actions.isEmpty) return;

    var nextLevel = profile.level;
    var nextXp = profile.xp + xpDelta;
    var nextMaxXp = max(1000, nextLevel * 1000);

    while (nextXp >= nextMaxXp) {
      nextXp -= nextMaxXp;
      nextLevel += 1;
      nextMaxXp = max(1000, nextLevel * 1000);
    }

    final updates = <String, dynamic>{};
    if (xpDelta > 0 || nextLevel != profile.level) {
      updates['xp'] = nextXp;
      updates['level'] = nextLevel;
    }

    if (updates.isNotEmpty) {
      await updateProfile(userId, updates);
    }

    for (final action in actions) {
      await logDecision(userId: userId, actionTaken: action, xpGained: 0);
    }
  }

  Future<bool> _reconcileDailyUsingLogColumns({
    required String userId,
    required int lookbackDays,
    required int disciplineXp,
  }) async {
    final profile = await getProfile(userId);
    if (profile == null || profile.dailyLimit <= 0) return true;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final sinceDate = DateTime.now()
        .subtract(Duration(days: lookbackDays))
        .toIso8601String()
        .substring(0, 10);

    List<dynamic> rows;
    bool useLegacyId = false;
    try {
      rows = await _client
          .from('daily_logs')
          .select(
            'date, spent_amount, transferred_to_savings, reconciled_at, reconciled_transfer_amount, reconciled_xp_awarded',
          )
          .eq('user_id', userId)
          .gte('date', sinceDate)
          .order('date', ascending: false);
    } on PostgrestException {
      final legacyUserId = await _resolveLegacyUserId(userId);
      if (legacyUserId == null) {
        return false;
      }
      useLegacyId = true;
      try {
        rows = await _client
            .from('daily_logs')
            .select(
              'date, spent_amount, transferred_to_savings, reconciled_at, reconciled_transfer_amount, reconciled_xp_awarded',
            )
            .eq('user_id', legacyUserId)
            .gte('date', sinceDate)
            .order('date', ascending: false);
      } on PostgrestException {
        // Reconcile kolonları henüz migration almamış olabilir.
        return false;
      }
    }

    int xpDelta = 0;
    final actions = <String>[];

    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final dateKey = (map['date'] as String?) ?? '';
      if (dateKey.isEmpty || dateKey == today || map['reconciled_at'] != null) {
        continue;
      }

      final spent = (map['spent_amount'] as num?)?.toDouble() ?? 0.0;
      final currentTransfer =
          (map['transferred_to_savings'] as num?)?.toDouble() ?? 0.0;
      final expectedTransfer = max(0.0, profile.dailyLimit - spent);
      final xpAwarded = spent <= profile.dailyLimit ? disciplineXp : 0;

      xpDelta += xpAwarded;

      final updatePayload = {
        'transferred_to_savings': expectedTransfer,
        'reconciled_at': DateTime.now().toIso8601String(),
        'reconciled_transfer_amount': expectedTransfer,
        'reconciled_xp_awarded': xpAwarded,
      };

      if (!useLegacyId) {
        await _client
            .from('daily_logs')
            .update(updatePayload)
            .eq('user_id', userId)
            .eq('date', dateKey);
      } else {
        final legacyUserId = await _resolveLegacyUserId(userId);
        if (legacyUserId != null) {
          await _client
              .from('daily_logs')
              .update(updatePayload)
              .eq('user_id', legacyUserId)
              .eq('date', dateKey);
        }
      }

      if ((currentTransfer - expectedTransfer).abs() > 0.01 || xpAwarded > 0) {
        actions.add(
          'AUTO_DAILY_RECONCILE_DB:$dateKey:spent=${spent.toStringAsFixed(2)}:transfer=${expectedTransfer.toStringAsFixed(2)}:xp=$xpAwarded',
        );
      }
    }

    if (xpDelta <= 0) {
      return true;
    }

    var nextLevel = profile.level;
    var nextXp = profile.xp + xpDelta;
    var nextMaxXp = max(1000, nextLevel * 1000);

    while (nextXp >= nextMaxXp) {
      nextXp -= nextMaxXp;
      nextLevel += 1;
      nextMaxXp = max(1000, nextLevel * 1000);
    }

    final updates = <String, dynamic>{'xp': nextXp, 'level': nextLevel};
    await updateProfile(userId, updates);

    for (final action in actions) {
      await logDecision(userId: userId, actionTaken: action, xpGained: 0);
    }

    return true;
  }

  Future<Set<String>> _getProcessedReconcileDates(String userId) async {
    List<dynamic> rows;
    try {
      rows = await _client
          .from('decisions_log')
          .select('action_taken')
          .eq('user_id', userId)
          .ilike('action_taken', 'AUTO_DAILY_RECONCILE:%')
          .limit(500);
    } on PostgrestException {
      final legacyUserId = await _resolveLegacyUserId(userId);
      if (legacyUserId == null) return <String>{};
      rows = await _client
          .from('decisions_log')
          .select('action_taken')
          .eq('user_id', legacyUserId)
          .ilike('action_taken', 'AUTO_DAILY_RECONCILE:%')
          .limit(500);
    }

    final dates = <String>{};
    for (final row in rows) {
      final action = (row as Map<String, dynamic>)['action_taken'] as String?;
      if (action == null || !action.startsWith('AUTO_DAILY_RECONCILE:')) {
        continue;
      }
      final parts = action.split(':');
      if (parts.length >= 2) {
        dates.add(parts[1]);
      }
    }
    return dates;
  }

  Future<int?> _resolveLegacyUserId(String authUserId) async {
    final direct = int.tryParse(authUserId);
    if (direct != null) return direct;

    try {
      final row = await _client
          .from('users')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      return (row?['id'] as num?)?.toInt();
    } on PostgrestException {
      return null;
    }
  }

  // ─── Crisis Events ────────────────────────────────────────────────────────

  Future<List<CrisisEventModel>> getCrisisEvents(String userId) async {
    final data = await _client
        .from('crisis_events')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => CrisisEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertCrisisEvent(CrisisEventModel event) =>
      _client.from('crisis_events').insert(event.toInsertJson());

  Future<void> updateCrisisResolution(String id, String strategy) => _client
      .from('crisis_events')
      .update({'resolution_strategy': strategy})
      .eq('id', id);

  // ─── Decisions Log ────────────────────────────────────────────────────────

  Future<void> logDecision({
    required String userId,
    required String actionTaken,
    int xpGained = 0,
  }) => _client
      .from('decisions_log')
      .insert(
        DecisionLogModel(
          id: '',
          userId: userId,
          actionTaken: actionTaken,
          xpGained: xpGained,
        ).toInsertJson(),
      );

  Future<List<DecisionLogModel>> getDecisionLog(String userId) async {
    final data = await _client
        .from('decisions_log')
        .select()
        .eq('user_id', userId)
        .order('id', ascending: false)
        .limit(50);
    return (data as List)
        .map((e) => DecisionLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Recurring Rules ──────────────────────────────────────────────────────

  Future<List<RecurringRuleModel>> getRecurringRules(String userId) async {
    final data = await _client
        .from('recurring_rules')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => RecurringRuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecurringRuleModel> insertRecurringRule(
    RecurringRuleModel rule,
  ) async {
    final payload = rule.toJson()..remove('id');
    final inserted = await _client
        .from('recurring_rules')
        .insert(payload)
        .select()
        .single();
    return RecurringRuleModel.fromJson(inserted);
  }

  Future<void> updateRecurringRule(RecurringRuleModel rule) async {
    final payload = rule.toJson()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at');
    await _client
        .from('recurring_rules')
        .update(payload)
        .eq('id', rule.id)
        .eq('user_id', rule.userId);
  }

  Future<void> deleteRecurringRule(String ruleId, String userId) async {
    await _client
        .from('recurring_rules')
        .delete()
        .eq('id', ruleId)
        .eq('user_id', userId);
  }

  /// Vadesi gelen aktif kuralları bugüne uygular.
  /// Her kural için balanceyi günceller ve `last_applied_date`'i set eder.
  /// Çağıran, dönen delta listesini HomeViewModel'a iletebilir.
  Future<double> applyDueRules(String userId) async {
    try {
      final result = await _client.rpc(
        'apply_due_recurring_rules',
        params: {'p_user_id': userId},
      );
      return (result as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Auth Helpers ─────────────────────────────────────────────────────────

  User? get currentUser {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId {
    try {
      return _client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges {
    try {
      return _client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream<AuthState>.empty();
    }
  }
}
