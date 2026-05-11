import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/mock_local_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final MockLocalDataSource _dataSource;

  const UserRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> getUserProfile() async {
    final model = await _dataSource.getUserProfile();
    return model.toEntity();
  }

  @override
  Future<void> updateUserXp(String userId, int xp) async {
    // Reserved for backend integration
  }
}
