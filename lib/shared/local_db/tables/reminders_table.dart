/// Table to track scheduled event reminders
/// Prevents duplicate reminders from being sent to users
class RemindersTable {
  static const String tableName = 'event_reminders';
  static const String id = 'id';
  static const String eventId = 'event_id';
  static const String userId = 'user_id';
  static const String ticketId = 'ticket_id';
  static const String reminderTime = 'reminder_time';
  static const String status = 'status'; // 'scheduled', 'sent', 'failed'
  static const String createdAt = 'created_at';
  static const String sentAt = 'sent_at';

  static const String createSql =
      '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $eventId TEXT NOT NULL,
      $userId TEXT NOT NULL,
      $ticketId TEXT NOT NULL,
      $reminderTime TEXT NOT NULL,
      $status TEXT NOT NULL DEFAULT 'scheduled',
      $createdAt TEXT NOT NULL,
      $sentAt TEXT,
      UNIQUE($eventId, $userId, $ticketId)
    )
  ''';
}
