import '../../domain/entities/event_entity.dart';
import '../../domain/entities/seat_entity.dart';
import 'event_datasource.dart';
import '../models/event_model.dart';
import '../models/seat_model.dart';
import '../../../../shared/local_db/database_helper.dart';
import '../../../../shared/local_db/tables/events_table.dart';
import '../../../../shared/local_db/tables/seats_table.dart';

class EventLocalDatasourceImpl implements EventLocalDatasource {
  final DatabaseHelper db;

  EventLocalDatasourceImpl({required this.db});

  @override
  Future<List<EventEntity>> getEvents() async {
    try {
      final results = await db.query(EventsTable.tableName);
      return results.map((map) => EventModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  @override
  Future<List<EventEntity>> getEventsByOrganizer(String organizerId) async {
    try {
      final results = await db.query(
        EventsTable.tableName,
        where: '${EventsTable.organizerId} = ?',
        whereArgs: [organizerId],
      );
      return results.map((map) => EventModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching events by organizer: $e');
    }
  }

  @override
  Future<EventEntity> getEventById(String id) async {
    try {
      final results = await db.query(
        EventsTable.tableName,
        where: '${EventsTable.id} = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) throw Exception('Event not found');
      return EventModel.fromMap(results.first);
    } catch (e) {
      throw Exception('Error fetching event: $e');
    }
  }

  @override
  Future<void> createEvent(EventEntity event) async {
    try {
      final model = EventModel.fromEntity(event);
      await db.insert(EventsTable.tableName, model.toMap());
    } catch (e) {
      throw Exception('Error creating event: $e');
    }
  }

  @override
  Future<void> updateEvent(EventEntity event) async {
    try {
      final model = EventModel.fromEntity(event);
      await db.update(
        EventsTable.tableName,
        model.toMap(),
        where: '${EventsTable.id} = ?',
        whereArgs: [event.id],
      );
    } catch (e) {
      throw Exception('Error updating event: $e');
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await db.delete(
        EventsTable.tableName,
        where: '${EventsTable.id} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error deleting event: $e');
    }
  }

  @override
  Future<List<SeatEntity>> getSeatsByEvent(String eventId) async {
    try {
      final eventRows = await db.query(
        EventsTable.tableName,
        where: '${EventsTable.id} = ?',
        whereArgs: [eventId],
      );
      final expectedCount = eventRows.isNotEmpty
          ? int.tryParse('${eventRows.first[EventsTable.totalSeats] ?? 0}') ?? 0
          : 0;

      final results = await db.query(
        SeatsTable.tableName,
        where: '${SeatsTable.eventId} = ?',
        whereArgs: [eventId],
      );
      final seats = results.map((map) => SeatModel.fromMap(map)).toList()
        ..sort((a, b) {
          final rowCompare = a.rowLabel.compareTo(b.rowLabel);
          if (rowCompare != 0) return rowCompare;
          return a.seatNumber.compareTo(b.seatNumber);
        });

      if (expectedCount > 0 && seats.length > expectedCount) {
        return seats.take(expectedCount).toList();
      }
      return seats;
    } catch (e) {
      throw Exception('Error fetching seats: $e');
    }
  }

  @override
  Future<void> createSeats(List<SeatEntity> seats) async {
    try {
      for (var seat in seats) {
        final model = SeatModel.fromEntity(seat);
        await db.insert(SeatsTable.tableName, model.toMap());
      }
    } catch (e) {
      throw Exception('Error creating seats: $e');
    }
  }

  @override
  Future<void> deleteSeatsByIds(String eventId, List<String> seatIds) async {
    if (seatIds.isEmpty) return;
    try {
      final placeholders = List.filled(seatIds.length, '?').join(',');
      await db.delete(
        SeatsTable.tableName,
        where:
            '${SeatsTable.eventId} = ? AND ${SeatsTable.id} IN ($placeholders)',
        whereArgs: [eventId, ...seatIds],
      );
    } catch (e) {
      throw Exception('Error deleting seats: $e');
    }
  }
}
