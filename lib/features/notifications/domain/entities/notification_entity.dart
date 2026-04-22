import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? eventId;
  final String createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.eventId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, body, eventId, createdAt];
}
