import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crisis_event_model.dart';
import '../models/daily_log_model.dart';
import '../models/decision_log_model.dart';
import '../models/profile_model.dart';
import '../models/recurring_transaction_model.dart';

/// Supabase istemcisine merkezi erişim sağlar.
/// Supabase.initialize() main.dart'ta çağrıldıktan sonra kullanılabilir.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ─── Auth ─────────────────────────────────────────────────────────────────

  bool get isSignedIn => _client.auth.currentUser != null;

  /// Oturum açık değilse anonim oturum açar.
  Future<void> ensureSignedIn() async {
    if (!isSignedIn) {
      await _client.auth.signInAnonymously();
    }
  }

  // ─── Profiles ────────────────────────────────────────────────────────────────

  Future<ProfileModel?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> updates) =>
      _client.from('profiles').update(updates).eq('id', userId);

  Future<void> updateXp(String userId, int xp) =>
      updateProfile(userId, {'Xp': xp});

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

  // ─── Daily Logs ───────────────────────────────────────────────────────────

  Future<List<DailyLogModel>> getRecentDailyLogs(
    String userId, {
    int days = 7,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final data = await _client
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        .gte('date', since.toIso8601String().substring(0, 10))
        .order('date', ascending: false);
    return (data as List)
        .map((e) => DailyLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertDailyLog({
    required String userId,
    required double spentAmount,
    required double transferredToSavings,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _client.from('daily_logs').upsert({
      'user_id': userId,
      'date': today,
      'spent_amount': spentAmount,
      'transferred_to_savings': transferredToSavings,
    }, onConflict: 'user_id,date');
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
