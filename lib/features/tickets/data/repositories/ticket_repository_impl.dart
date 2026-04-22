import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/event_booking_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_local_datasource.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketLocalDatasource local;

  TicketRepositoryImpl({required this.local});

  @override
  Future<TicketEntity> bookTicket({
    required String eventId,
    required String userId,
    required String seatId,
  }) {
    return local.bookTicket(eventId: eventId, userId: userId, seatId: seatId);
  }

  @override
  Future<List<TicketEntity>> getTicketsByUser(String userId) {
    return local.getTicketsByUser(userId);
  }

  @override
  Future<List<EventBookingEntity>> getBookingsByEvent(String eventId) {
    return local.getBookingsByEvent(eventId);
  }

  @override
  Future<TicketEntity?> getTicketById(String id) {
    return local.getTicketById(id);
  }

  @override
  Future<TicketEntity?> validateTicket(String qrData) {
    return local.validateTicket(qrData);
  }

  @override
  Future<void> markTicketUsed(String ticketId) {
    return local.markTicketUsed(ticketId);
  }
}
