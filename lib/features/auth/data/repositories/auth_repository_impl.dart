import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource localDatasource;

  AuthRepositoryImpl({required this.localDatasource});

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    return localDatasource.login(email: email, password: password);
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? contactNumber,
  }) async {
    return localDatasource.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }

  @override
  Future<UserEntity> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? password,
    String? contactNumber,
  }) {
    return localDatasource.updateProfile(
      userId: userId,
      name: name,
      email: email,
      password: password,
      contactNumber: contactNumber,
    );
  }

  @override
  Future<void> logout() => localDatasource.logout();

  @override
  Future<UserEntity?> getCurrentUser() => localDatasource.getCurrentUser();
}
