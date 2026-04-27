import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String password;

  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.createdAt,
    required this.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        password: map['password'],
        role: map['role'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'created_at': createdAt,
      };
}
