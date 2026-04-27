import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/failures.dart';
import '../../../../shared/local_db/database_helper.dart';
import '../../../../shared/local_db/tables/users_table.dart';
import '../models/user_model.dart';

class AuthLocalDatasource {
  final DatabaseHelper db;
  final SharedPreferences prefs;

  AuthLocalDatasource({required this.db, required this.prefs});

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );
      if (results.isEmpty) {
        throw AuthException(message: 'Invalid email or password');
      }
      final user = UserModel.fromMap(results.first);
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toMap()));
      return user;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (existing.isNotEmpty) {
        throw AuthException(message: 'Email already registered');
      }
      final user = UserModel(
        id: const Uuid().v4(),
        name: name,
        email: email,
        password: password,
        role: role,
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('users', user.toMap());
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toMap()));
      return user;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<void> logout() async {
    await prefs.remove(AppConstants.userKey);
  }

  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? password,
  }) async {
    try {
      final existingRows = await db.query(
        UsersTable.tableName,
        where: '${UsersTable.id} = ?',
        whereArgs: [userId],
      );
      if (existingRows.isEmpty) {
        throw AuthException(message: 'User not found');
      }

      final existing = UserModel.fromMap(existingRows.first);

      if (email != existing.email) {
        final sameEmail = await db.query(
          UsersTable.tableName,
          where: '${UsersTable.email} = ? AND ${UsersTable.id} != ?',
          whereArgs: [email, userId],
        );
        if (sameEmail.isNotEmpty) {
          throw AuthException(message: 'Email already in use');
        }
      }

      final updated = UserModel(
        id: existing.id,
        name: name,
        email: email,
        password: (password != null && password.isNotEmpty)
            ? password
            : existing.password,
        role: existing.role,
        createdAt: existing.createdAt,
      );

      await db.update(
        UsersTable.tableName,
        updated.toMap(),
        where: '${UsersTable.id} = ?',
        whereArgs: [userId],
      );
      await prefs.setString(AppConstants.userKey, jsonEncode(updated.toMap()));
      return updated;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final json = prefs.getString(AppConstants.userKey);
    if (json == null) return null;
    return UserModel.fromMap(jsonDecode(json));
  }
}
