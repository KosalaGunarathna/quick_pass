import 'events_table.dart';
import 'seats_table.dart';
import 'users_table.dart';

class TicketsTable {
  static const String tableName = 'tickets';
  static const String id = 'id';
  static const String eventId = 'event_id';
  static const String userId = 'user_id';
  static const String seatId = 'seat_id';
  static const String qrData = 'qr_data';
  static const String status = 'status';
  static const String bookedAt = 'booked_at';

  static const String createSql =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $eventId TEXT NOT NULL,
      $userId TEXT NOT NULL,
      $seatId TEXT NOT NULL,
      $qrData TEXT NOT NULL UNIQUE,
      $status TEXT NOT NULL DEFAULT 'active',
      $bookedAt TEXT NOT NULL,
      FOREIGN KEY ($eventId) REFERENCES ${EventsTable.tableName}(${EventsTable.id}),
      FOREIGN KEY ($userId) REFERENCES ${UsersTable.tableName}(${UsersTable.id}),
      FOREIGN KEY ($seatId) REFERENCES ${SeatsTable.tableName}(${SeatsTable.id})
    )
  ''';
}
