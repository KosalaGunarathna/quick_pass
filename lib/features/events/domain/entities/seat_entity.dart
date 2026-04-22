import 'package:equatable/equatable.dart';

class SeatEntity extends Equatable {
  final String id;
  final String eventId;
  final int seatNumber;
  final String rowLabel;
  final String status; // available, booked, locked
  final String? ticketId;
  final bool isAvailable;

  const SeatEntity({
    required this.id,
    required this.eventId,
    required this.seatNumber,
    required this.rowLabel,
    required this.status,
    this.ticketId,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [
    id,
    eventId,
    seatNumber,
    rowLabel,
    status,
    ticketId,
    isAvailable,
  ];
}
