import 'package:smart_event/features/events/domain/entities/seat_entity.dart';
import '../../../../shared/local_db/tables/seats_table.dart';

class SeatModel extends SeatEntity {
  const SeatModel({
    required String id,
    required String eventId,
    required int seatNumber,
    required String rowLabel,
    required String status,
    String? ticketId,
    required bool isAvailable,
  }) : super(
         id: id,
         eventId: eventId,
         seatNumber: seatNumber,
         rowLabel: rowLabel,
         status: status,
         ticketId: ticketId,
         isAvailable: isAvailable,
       );

  factory SeatModel.fromEntity(SeatEntity entity) {
    return SeatModel(
      id: entity.id,
      eventId: entity.eventId,
      seatNumber: entity.seatNumber,
      rowLabel: entity.rowLabel,
      status: entity.status,
      ticketId: entity.ticketId,
      isAvailable: entity.isAvailable,
    );
  }

  factory SeatModel.fromMap(Map<String, dynamic> map) {
    return SeatModel(
      id: map['id'] ?? '',
      eventId: map[SeatsTable.eventId] ?? '',
      seatNumber: int.tryParse('${map[SeatsTable.seatNumber] ?? 0}') ?? 0,
      rowLabel: map[SeatsTable.rowLabel] ?? '',
      status: map[SeatsTable.status] ?? 'available',
      ticketId: map[SeatsTable.ticketId],
      isAvailable: (map[SeatsTable.status] ?? 'available') == 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      SeatsTable.eventId: eventId,
      SeatsTable.seatNumber: seatNumber.toString(),
      SeatsTable.rowLabel: rowLabel,
      SeatsTable.status: status,
      SeatsTable.ticketId: ticketId,
    };
  }
}
