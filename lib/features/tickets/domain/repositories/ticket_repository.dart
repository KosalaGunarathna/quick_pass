import '../entities/ticket_entity.dart';
import '../entities/event_booking_entity.dart';

abstract class TicketRepository {
  Future<TicketEntity> bookTicket({
    required String eventId,
    required String userId,
    required String seatId,
  });
  Future<List<TicketEntity>> getTicketsByUser(String userId);
  Future<List<EventBookingEntity>> getBookingsByEvent(String eventId);
  Future<TicketEntity?> getTicketById(String id);
  Future<TicketEntity?> validateTicket(String qrData);
  Future<void> markTicketUsed(String ticketId);
}

// Use cases
class BookTicketUseCase {
  final TicketRepository repository;
  BookTicketUseCase(this.repository);
  Future<TicketEntity> call({
    required String eventId,
    required String userId,
    required String seatId,
  }) => repository.bookTicket(eventId: eventId, userId: userId, seatId: seatId);
}

class GetMyTicketsUseCase {
  final TicketRepository repository;
  GetMyTicketsUseCase(this.repository);
  Future<List<TicketEntity>> call(String userId) =>
      repository.getTicketsByUser(userId);
}

class GetEventBookingsUseCase {
  final TicketRepository repository;
  GetEventBookingsUseCase(this.repository);
  Future<List<EventBookingEntity>> call(String eventId) =>
      repository.getBookingsByEvent(eventId);
}

class ValidateTicketUseCase {
  final TicketRepository repository;
  ValidateTicketUseCase(this.repository);
  Future<TicketEntity?> call(String qrData) =>
      repository.validateTicket(qrData);
}

class MarkTicketUsedUseCase {
  final TicketRepository repository;
  MarkTicketUsedUseCase(this.repository);
  Future<void> call(String ticketId) => repository.markTicketUsed(ticketId);
}
