class NotificationsTable {
  static const String tableName = 'notifications';
  static const String id = 'id';
  static const String title = 'title';
  static const String body = 'body';
  static const String eventId = 'event_id';
  static const String createdAt = 'created_at';

  static const String createSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $id TEXT PRIMARY KEY,
      $title TEXT NOT NULL,
      $body TEXT NOT NULL,
      $eventId TEXT,
      $createdAt TEXT NOT NULL
    )
  ''';
}
