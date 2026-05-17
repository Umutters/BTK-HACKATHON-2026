import '../../core/constants/app_env.dart';
import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';
import '../services/supabase_service.dart';

class QuestRepositoryImpl implements QuestRepository {
  final SupabaseService _supabase;

  QuestRepositoryImpl({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService.instance;

  static const List<QuestEntity> _fallbackQuests = [
    QuestEntity(
      id: 'q1',
      title: 'Gunluk Limit Koru',
      description: 'Bugun harcama limitini asma',
      xpReward: 200,
      status: QuestStatus.notStarted,
      iconName: 'limit',
    ),
    QuestEntity(
      id: 'q2',
      title: 'Tasarrufa Aktar',
      description: 'Birikime en az 50 TL aktar',
      xpReward: 300,
      status: QuestStatus.notStarted,
      iconName: 'savings',
    ),
    QuestEntity(
      id: 'q3',
      title: 'Kahine Sor',
      description: 'AI danismanina bir soru sor',
      xpReward: 100,
      status: QuestStatus.notStarted,
      iconName: 'oracle',
    ),
  ];

  Future<String?> _resolveUserId() async {
    var userId = _supabase.currentUserId;
    if (userId != null) return userId;

    // Supabase config varsa anonim oturumu bir kez dene.
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

  @override
  Future<List<QuestEntity>> getDailyQuests() async {
    final userId = await _resolveUserId();
    if (userId == null) {
      return _fallbackQuests;
    }

    final models = await _supabase.getOrCreateDailyQuests(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> startQuest(String questId) async {
    final userId = await _resolveUserId();
    if (userId == null) {
      return;
    }
    await _supabase.startDailyQuest(userId, questId);
  }

  @override
  Future<void> completeQuest(String questId) async {
    final userId = await _resolveUserId();
    if (userId == null) {
      return;
    }
    await _supabase.completeDailyQuest(userId, questId);
  }
}
