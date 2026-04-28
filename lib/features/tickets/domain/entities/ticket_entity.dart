import 'package:equatable/equatable.dart';

// Entity
class TicketEntity extends Equatable {
  final String id;
  final String eventId;
  final String userId;
  final String seatId;
  final String qrData;
  final String status; // 'active', 'used', 'cancelled'
  final String bookedAt;
  final String? seatNumber;
  final String? rawLabel;
  final String? userName; // Ticket owner's name
  final String? userEmail; // Ticket owner's email
  final String? userContact; // Ticket owner's contact number

  const TicketEntity({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.seatId,
    required this.qrData,
    required this.status,
    required this.bookedAt,
    this.seatNumber,
    this.rawLabel,
    this.userName,
    this.userEmail,
    this.userContact,
  });

  bool get isActive => status == 'active';
  bool get isUsed => status == 'used';

  @override
  List<Object?> get props => [id, status];
}
