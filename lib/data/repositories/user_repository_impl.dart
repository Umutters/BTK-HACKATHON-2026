import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_datasource.dart';
import '../services/supabase_service.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalDataSource _dataSource;
  final SupabaseService _supabase;

  UserRepositoryImpl(this._dataSource) : _supabase = SupabaseService.instance;

  @override
  Future<UserEntity> getUserProfile() async {
    final userId = _supabase.currentUserId;
    if (userId != null) {
      try {
        final profile = await _supabase.getProfile(userId);
        if (profile != null) return profile.toEntity();
      } catch (_) {
        // Supabase erişilemiyorsa local'e geç
      }
    }
    final model = await _dataSource.getUserProfile();
    return model.toEntity();
  }

  @override
  Future<void> updateUserXp(String userId, int xp) async {
    try {
      await _supabase.updateXp(userId, xp);
    } catch (_) {
      // ignore: Supabase erişilemiyorsa xp güncellemesi atlanır
    }
  }
}
