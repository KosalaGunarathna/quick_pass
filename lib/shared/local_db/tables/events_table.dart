import 'users_table.dart';

class EventsTable {
  static const String tableName = 'events';
  static const String id = 'id';
  static const String title = 'title';
  static const String description = 'description';
  static const String category = 'category';
  static const String eventDate = 'event_date';
  static const String location = 'location';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String imageUrl = 'image_url';
  static const String totalSeats = 'total_seats';
  static const String availableSeats = 'available_seats';
  static const String organizerId = 'organizer_id';
  static const String ticketPrice = 'ticket_price';
  static const String isFeatured = 'is_featured';
  static const String createdAt = 'created_at';

  static const String createSql =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $title TEXT NOT NULL,
      $description TEXT NOT NULL,
      $category TEXT NOT NULL,
      $eventDate TEXT NOT NULL,
      $location TEXT NOT NULL,
      $latitude REAL,
      $longitude REAL,
      $imageUrl TEXT,
      $totalSeats INTEGER NOT NULL,
      $availableSeats INTEGER NOT NULL,
      $organizerId TEXT NOT NULL,
      $ticketPrice REAL NOT NULL,
      $isFeatured INTEGER NOT NULL DEFAULT 0,
      $createdAt TEXT NOT NULL,
      FOREIGN KEY ($organizerId) REFERENCES ${UsersTable.tableName}(${UsersTable.id})
    )
  ''';
}
