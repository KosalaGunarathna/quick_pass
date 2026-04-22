import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<UserEntity> call({required String email, required String password}) {
    return repository.login(email: email, password: password);
  }
}

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<UserEntity> call({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return repository.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }
}

class LogoutUseCase {
  final AuthRepository repository;
  LogoutUseCase(this.repository);

  Future<void> call() => repository.logout();
}

class UpdateProfileUseCase {
  final AuthRepository repository;
  UpdateProfileUseCase(this.repository);

  Future<UserEntity> call({
    required String userId,
    required String name,
    required String email,
    String? password,
  }) {
    return repository.updateProfile(
      userId: userId,
      name: name,
      email: email,
      password: password,
    );
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  Future<UserEntity?> call() => repository.getCurrentUser();
}
