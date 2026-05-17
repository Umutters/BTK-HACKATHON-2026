import '../../core/constants/app_env.dart';
import '../models/profile_model.dart';
import '../models/quest_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/daily_log_model.dart';
import '../models/crisis_event_model.dart';
import '../models/decision_log_model.dart';
import '../services/supabase_service.dart';

/// Supabase tabanlı veri kaynağı.
/// mock_local_datasource.dart'ın yerini alır.
class SupabaseDataSource {
  final SupabaseService _supabase;

  SupabaseDataSource({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService.instance;

  Future<String?> _resolveUserId() async {
    var userId = _supabase.currentUserId;
    if (userId != null) return userId;

    if (AppEnv.supabaseUrl.isNotEmpty && AppEnv.supabaseAnonKey.isNotEmpty) {
      try {
        await _supabase.ensureSignedIn();
      } catch (_) {
        return null;
      }
      userId = _supabase.currentUserId;
    }

    return userId;
  }

  // ─── Profile ─────────────────────────────────────────────────────────────

  Future<ProfileModel> getUserProfile() async {
    final userId = await _resolveUserId();
    if (userId == null) {
      throw Exception('Supabase kullanicisi bulunamadi.');
    }
    final profile = await _supabase.getProfile(userId);
    if (profile == null) throw Exception('Profil bulunamadı: $userId');
    return profile;
  }

  Future<void> updateUserXp(String userId, int xp) =>
      _supabase.updateXp(userId, xp);

  // ─── Transactions ─────────────────────────────────────────────────────────

  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    final userId = await _resolveUserId();
    if (userId == null) return const [];
    return _supabase.getRecurringTransactions(userId);
  }

  // ─── Recurring Rules ──────────────────────────────────────────────────────

  Future<List<RecurringRuleModel>> getRecurringRules() async {
    final userId = await _resolveUserId();
    if (userId == null) return const [];
    return _supabase.getRecurringRules(userId);
  }

  // ─── Daily Logs ───────────────────────────────────────────────────────────

  Future<List<DailyLogModel>> getRecentDailyLogs({int days = 7}) async {
    final userId = await _resolveUserId();
    if (userId == null) return const [];
    return _supabase.getRecentDailyLogs(userId, days: days);
  }

  Future<void> logDailySpending({
    required double spentAmount,
    required double transferredToSavings,
  }) async {
    final userId = await _resolveUserId();
    if (userId == null) return;
    await _supabase.insertDailyLog(
      userId: userId,
      spentAmount: spentAmount,
      transferredToSavings: transferredToSavings,
    );
  }

  // ─── Crisis Events ────────────────────────────────────────────────────────

  Future<List<CrisisEventModel>> getCrisisEvents() async {
    final userId = await _resolveUserId();
    if (userId == null) return const [];
    return _supabase.getCrisisEvents(userId);
  }

  Future<void> addCrisisEvent(CrisisEventModel event) =>
      _supabase.insertCrisisEvent(event);

  // ─── Decisions Log ────────────────────────────────────────────────────────

  Future<void> logDecision({
    required String actionTaken,
    int xpGained = 0,
  }) async {
    final userId = await _resolveUserId();
    if (userId == null) return;
    await _supabase.logDecision(
      userId: userId,
      actionTaken: actionTaken,
      xpGained: xpGained,
    );
  }

  Future<List<DecisionLogModel>> getDecisionLog() async {
    final userId = await _resolveUserId();
    if (userId == null) return const [];
    return _supabase.getDecisionLog(userId);
  }

  // ─── Quests (mock — gerçek tablo eklenince güncelle) ─────────────────────

  Future<List<QuestModel>> getDailyQuests() async {
    return const [
      QuestModel(
        id: 'q1',
        title: 'Günlük Limitini Koru',
        description: 'Günlük harcama limitini aşma',
        xpReward: 150,
        status: 'notStarted',
        iconName: 'limit',
      ),
      QuestModel(
        id: 'q2',
        title: 'Tasarruf Hedefi',
        description: 'Havuzuna en az 50 TL aktar',
        xpReward: 200,
        status: 'notStarted',
        iconName: 'savings',
      ),
    ];
  }
}
