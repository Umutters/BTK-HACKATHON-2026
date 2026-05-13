import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crisis_event_model.dart';
import '../models/daily_log_model.dart';
import '../models/decision_log_model.dart';
import '../models/profile_model.dart';
import '../models/quest_model.dart';
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
      'title': "Oracle'a Sor",
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
    final profile = await getProfile(userId);
    if (profile == null) return;
    final newPool = profile.savingsPool + amount;
    await updateProfile(userId, {'savings_pool': newPool});
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

  // ─── Daily Quests ───────────────────────────────────────────────────────

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

  Future<void> insertDailyLog({
    required String userId,
    required double spentAmount,
    required double transferredToSavings,
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

      if (existing == null) {
        await _client.from('daily_logs').insert({
          'user_id': userId,
          'date': today,
          'spent_amount': mergedSpent,
          'transferred_to_savings': mergedTransferred,
        });
      } else {
        await _client
            .from('daily_logs')
            .update({
              'spent_amount': mergedSpent,
              'transferred_to_savings': mergedTransferred,
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

    if (existing == null) {
      await _client.from('daily_logs').insert({
        'user_id': legacyUserId,
        'date': today,
        'spent_amount': mergedSpent,
        'transferred_to_savings': mergedTransferred,
      });
    } else {
      await _client
          .from('daily_logs')
          .update({
            'spent_amount': mergedSpent,
            'transferred_to_savings': mergedTransferred,
          })
          .eq('user_id', legacyUserId)
          .eq('date', today);
    }
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
        .order('id', ascending: false);
    return (data as List)
        .map((e) => CrisisEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertCrisisEvent(CrisisEventModel event) =>
      _client.from('crisis_events').insert(event.toInsertJson());

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

  // ─── Auth Helpers ─────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
