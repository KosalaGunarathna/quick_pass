import 'package:equatable/equatable.dart';

class EventBookingEntity extends Equatable {
  final String ticketId;
  final String seatId;
  final String seatLabel;
  final String userId;
  final String userName;
  final String userEmail;
  final String status;
  final String bookedAt;

  const EventBookingEntity({
    required this.ticketId,
    required this.seatId,
    required this.seatLabel,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.bookedAt,
  });

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [ticketId, seatId, userId, status, bookedAt];
}
