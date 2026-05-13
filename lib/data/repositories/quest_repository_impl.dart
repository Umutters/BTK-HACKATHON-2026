import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';
import '../services/supabase_service.dart';

class QuestRepositoryImpl implements QuestRepository {
  final SupabaseService _supabase;

  QuestRepositoryImpl({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService.instance;

  @override
  Future<List<QuestEntity>> getDailyQuests() async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      throw Exception('Kullanıcı oturum açmamış.');
    }

    final models = await _supabase.getOrCreateDailyQuests(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> startQuest(String questId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      throw Exception('Kullanıcı oturum açmamış.');
    }
    await _supabase.startDailyQuest(userId, questId);
  }

  @override
  Future<void> completeQuest(String questId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      throw Exception('Kullanıcı oturum açmamış.');
    }
    await _supabase.completeDailyQuest(userId, questId);
  }
}
