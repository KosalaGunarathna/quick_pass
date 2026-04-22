import '../../domain/entities/event_entity.dart';
import '../../domain/entities/seat_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  final EventLocalDatasource local;
  final EventRemoteDatasource remote;

  EventRepositoryImpl({required this.local, required this.remote});

  @override
  Future<List<EventEntity>> getEvents() async {
    final localEvents = await local.getEvents();
    try {
      final remoteEvents = await remote.getEvents();
      final merged = <String, EventEntity>{
        for (final event in localEvents) event.id: event,
      };
      for (final event in remoteEvents) {
        merged[event.id] = event;
      }
      return merged.values.toList();
    } catch (_) {
      return localEvents;
    }
  }

  @override
  Future<List<EventEntity>> getEventsByOrganizer(String organizerId) =>
      local.getEventsByOrganizer(organizerId);

  @override
  Future<EventEntity> getEventById(String id) async {
    try {
      return await local.getEventById(id);
    } catch (e) {
      return await remote.getEventById(id);
    }
  }

  @override
  Future<void> createEvent(EventEntity event) async {
    await local.createEvent(event);
  }

  @override
  Future<void> updateEvent(EventEntity event) async {
    await local.updateEvent(event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await local.deleteEvent(id);
  }

  @override
  Future<List<SeatEntity>> getSeatsByEvent(String eventId) =>
      local.getSeatsByEvent(eventId);

  @override
  Future<void> createSeats(List<SeatEntity> seats) async {
    await local.createSeats(seats);
  }

  @override
  Future<void> deleteSeatsByIds(String eventId, List<String> seatIds) {
    return local.deleteSeatsByIds(eventId, seatIds);
  }
}
