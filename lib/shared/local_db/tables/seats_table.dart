import 'events_table.dart';

class SeatsTable {
  static const String tableName = 'seats';
  static const String id = 'id';
  static const String eventId = 'event_id';
  static const String seatNumber = 'seat_number';
  static const String rowLabel = 'row_label';
  static const String status = 'status';
  static const String ticketId = 'ticket_id';

  static const String createSql =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $eventId TEXT NOT NULL,
      $seatNumber TEXT NOT NULL,
      $rowLabel TEXT NOT NULL,
      $status TEXT NOT NULL DEFAULT 'available',
      $ticketId TEXT,
      FOREIGN KEY ($eventId) REFERENCES ${EventsTable.tableName}(${EventsTable.id})
    )
  ''';
}
