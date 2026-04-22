import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  Future<UserEntity> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? password,
  });
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}
