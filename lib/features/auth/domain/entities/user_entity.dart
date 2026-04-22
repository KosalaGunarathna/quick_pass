import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'organizer' or 'user'
  final String createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  bool get isOrganizer => role == 'organizer';

  @override
  List<Object?> get props => [id, email, role];
}