import '../entities/event_entity.dart';
import '../entities/seat_entity.dart';

abstract class EventRepository {
  Future<List<EventEntity>> getEvents();
  Future<List<EventEntity>> getEventsByOrganizer(String organizerId);
  Future<EventEntity> getEventById(String id);
  Future<void> createEvent(EventEntity event);
  Future<void> updateEvent(EventEntity event);
  Future<void> deleteEvent(String id);
  Future<List<SeatEntity>> getSeatsByEvent(String eventId);
  Future<void> createSeats(List<SeatEntity> seats);
  Future<void> deleteSeatsByIds(String eventId, List<String> seatIds);
}
