import 'package:uuid/uuid.dart';
import '../../../../shared/local_db/database_helper.dart';
import '../../../../shared/local_db/tables/reminders_table.dart';
import '../../../../shared/local_db/tables/events_table.dart';
import '../../../../shared/local_db/tables/tickets_table.dart';
import '../../../../shared/local_db/tables/users_table.dart';
import 'notification_service.dart';

/// Service to handle event reminders
/// Schedules notifications 1 hour before event start time for users with bookings
class EventReminderService {
  EventReminderService._();
  static final EventReminderService instance = EventReminderService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  /// Initialize reminder tracking (ensure table exists)
  Future<void> init() async {
    // Table is created during database migration
  }

  /// Schedule reminders for upcoming events
  /// Fetches events starting within the next 2 hours
  /// and schedules reminders for all users with active bookings
  Future<void> scheduleUpcomingReminders() async {
    try {
      final now = DateTime.now();

      // Get events that start between now and 2 hours from now
      final twoHoursLater = now.add(const Duration(hours: 2));
      final nowIso = now.toIso8601String();
      final twoHoursLaterIso = twoHoursLater.toIso8601String();

      // Query upcoming events
      final upcomingEvents = await _db.query(
        EventsTable.tableName,
        where:
            '${EventsTable.eventDate} >= ? AND ${EventsTable.eventDate} <= ?',
        whereArgs: [nowIso, twoHoursLaterIso],
        orderBy: '${EventsTable.eventDate} ASC',
      );

      if (upcomingEvents.isEmpty) {
        return;
      }

      // For each upcoming event, check and schedule reminders
      for (final eventRow in upcomingEvents) {
        final eventId = eventRow[EventsTable.id] as String;
        final eventTitle = eventRow[EventsTable.title] as String;
        final eventDateStr = eventRow[EventsTable.eventDate] as String;
        final eventDate = DateTime.parse(eventDateStr);

        // Get all active bookings for this event
        final bookings = await _getActiveBookingsForEvent(eventId);

        // For each booking, schedule a reminder
        for (final booking in bookings) {
          await _scheduleReminderForBooking(
            eventId: eventId,
            eventTitle: eventTitle,
            eventDate: eventDate,
            booking: booking,
          );
        }
      }
    } catch (e) {
      print('Error scheduling reminders: $e');
    }
  }

  /// Get all active bookings for an event
  Future<List<Map<String, dynamic>>> _getActiveBookingsForEvent(
    String eventId,
  ) async {
    return await _db.rawQuery(
      '''
      SELECT 
        t.${TicketsTable.id} AS ticket_id,
        t.${TicketsTable.userId} AS user_id,
        u.${UsersTable.email} AS user_email,
        u.${UsersTable.name} AS user_name
      FROM ${TicketsTable.tableName} t
      INNER JOIN ${UsersTable.tableName} u ON u.${UsersTable.id} = t.${TicketsTable.userId}
      WHERE t.${TicketsTable.eventId} = ? AND t.${TicketsTable.status} = 'active'
      ''',
      [eventId],
    );
  }

  /// Schedule reminder for a specific booking
  Future<void> _scheduleReminderForBooking({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required Map<String, dynamic> booking,
  }) async {
    try {
      final userId = booking['user_id'] as String;
      final ticketId = booking['ticket_id'] as String;
      final userEmail = booking['user_email'] as String?;
      final userName = booking['user_name'] as String?;

      // Check if reminder already exists for this ticket
      final existingReminders = await _db.query(
        RemindersTable.tableName,
        where: '${RemindersTable.ticketId} = ?',
        whereArgs: [ticketId],
      );

      // If reminder already scheduled, skip
      if (existingReminders.isNotEmpty) {
        return;
      }

      // Calculate reminder time (1 hour before event)
      final reminderTime = eventDate.subtract(const Duration(hours: 1));

      // Don't schedule if reminder time is in the past
      if (reminderTime.isBefore(DateTime.now())) {
        return;
      }

      // Create reminder record
      final reminderId = const Uuid().v4();
      final now = DateTime.now();

      await _db.insert(RemindersTable.tableName, {
        RemindersTable.id: reminderId,
        RemindersTable.eventId: eventId,
        RemindersTable.userId: userId,
        RemindersTable.ticketId: ticketId,
        RemindersTable.reminderTime: reminderTime.toIso8601String(),
        RemindersTable.status: 'scheduled',
        RemindersTable.createdAt: now.toIso8601String(),
      });

      // Schedule the actual notification
      await _notificationService.scheduleEventReminder(
        eventId: eventId,
        eventTitle: eventTitle,
        eventDate: eventDate,
      );

      print('Scheduled reminder for user $userId for event $eventTitle');
    } catch (e) {
      print('Error scheduling reminder for booking: $e');
    }
  }

  /// Mark a reminder as sent
  Future<void> markReminderAsSent(String reminderId) async {
    try {
      await _db.update(
        RemindersTable.tableName,
        {
          RemindersTable.status: 'sent',
          RemindersTable.sentAt: DateTime.now().toIso8601String(),
        },
        where: '${RemindersTable.id} = ?',
        whereArgs: [reminderId],
      );
    } catch (e) {
      print('Error marking reminder as sent: $e');
    }
  }

  /// Clear old reminders (older than 7 days)
  Future<void> clearOldReminders() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      await _db.delete(
        RemindersTable.tableName,
        where: '${RemindersTable.createdAt} < ?',
        whereArgs: [sevenDaysAgo.toIso8601String()],
      );
    } catch (e) {
      print('Error clearing old reminders: $e');
    }
  }

  /// Get pending reminders
  Future<List<Map<String, dynamic>>> getPendingReminders() async {
    return await _db.query(
      RemindersTable.tableName,
      where: '${RemindersTable.status} = ?',
      whereArgs: ['scheduled'],
      orderBy: '${RemindersTable.reminderTime} ASC',
    );
  }
}
