import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetUserProgressUseCase {
  final UserRepository _repository;

  const GetUserProgressUseCase(this._repository);

  Future<UserEntity> call() => _repository.getUserProfile();
}
