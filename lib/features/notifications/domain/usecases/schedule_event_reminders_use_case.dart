import 'package:flutter/foundation.dart';
import 'package:smart_event/features/notifications/data/datasources/event_reminder_service.dart';
//import '../datasources/event_reminder_service.dart';

/// Use case to schedule event reminders for upcoming events
/// Fetches events within the next 2 hours and schedules notifications
/// for all users with active bookings
class ScheduleEventRemindersUseCase {
  final EventReminderService _reminderService;

  ScheduleEventRemindersUseCase(this._reminderService);

  /// Execute the reminder scheduling
  Future<void> call() async {
    try {
      debugPrint(
        '[ScheduleEventRemindersUseCase] Checking for upcoming events...',
      );
      await _reminderService.scheduleUpcomingReminders();
      debugPrint(
        '[ScheduleEventRemindersUseCase] Reminder scheduling completed',
      );
    } catch (e) {
      debugPrint('[ScheduleEventRemindersUseCase] Error: $e');
    }
  }

  /// Clear old reminders (runs periodically)
  Future<void> clearOldReminders() async {
    try {
      await _reminderService.clearOldReminders();
    } catch (e) {
      debugPrint(
        '[ScheduleEventRemindersUseCase] Error clearing reminders: $e',
      );
    }
  }
}
