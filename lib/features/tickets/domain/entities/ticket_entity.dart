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
  });

  bool get isActive => status == 'active';
  bool get isUsed => status == 'used';

  @override
  List<Object?> get props => [id, status];
}
