# Event Reminder System Documentation

## Overview
The Event Reminder System automatically sends push notifications to users 1 hour before the start time of events they have booked seats for.

## Components

### 1. Reminders Tracking Table (`reminders_table.dart`)
- **Location**: `lib/shared/local_db/tables/reminders_table.dart`
- **Purpose**: Tracks scheduled reminders to prevent duplicate notifications
- **Fields**:
  - `id`: Unique identifier (UUID)
  - `eventId`: Reference to the event
  - `userId`: Reference to the user who booked
  - `ticketId`: Reference to the specific ticket/booking
  - `reminderTime`: Calculated time when reminder should be sent (1 hour before event)
  - `status`: 'scheduled', 'sent', or 'failed'
  - `createdAt`: When the reminder was created
  - `sentAt`: When the reminder was actually sent

### 2. Event Reminder Service (`event_reminder_service.dart`)
- **Location**: `lib/features/notifications/data/datasources/event_reminder_service.dart`
- **Key Methods**:
  - `scheduleUpcomingReminders()`: Main method that:
    - Fetches events starting within the next 2 hours
    - Gets all active bookings for those events
    - Schedules notifications for each user
  - `markReminderAsSent()`: Marks reminder as sent in the database
  - `clearOldReminders()`: Removes reminders older than 7 days
  - `getPendingReminders()`: Retrieves all scheduled but not yet sent reminders

### 3. Schedule Event Reminders Use Case (`schedule_event_reminders_use_case.dart`)
- **Location**: `lib/features/notifications/domain/usecases/schedule_event_reminders_use_case.dart`
- **Purpose**: Provides a clean interface for reminder scheduling
- **Methods**:
  - `call()`: Execute reminder scheduling for upcoming events
  - `clearOldReminders()`: Cleanup old reminders

## Integration Points

### Main App Initialization (`main.dart`)
```dart
// Initializes the reminder service at app startup
await EventReminderService.instance.init();

// Schedules reminders for all upcoming events on first launch
await _scheduleInitialReminders();
```

### Periodic Reminder Scheduling (`app.dart`)
```dart
// Checks for new reminders every 10 minutes
// This ensures reminders are scheduled for bookings made after app startup
Timer.periodic(
  const Duration(minutes: 10),
  (_) => _scheduleRemindersUseCase.call(),
);
```

## Workflow

1. **App Launch**
   - NotificationService and EventReminderService are initialized
   - Initial reminder scheduling checks for upcoming events
   - Reminders are created and scheduled via NotificationService

2. **Periodic Checks (Every 10 minutes)**
   - App checks for upcoming events (within 2 hours)
   - New bookings made since last check are identified
   - Reminders are scheduled for new bookings

3. **Notification Scheduling**
   - When a reminder is created, it's added to the reminders table with status 'scheduled'
   - NotificationService schedules the actual local notification
   - Notification is set to trigger 1 hour before event start time

4. **Cleanup**
   - Old reminders (>7 days) are automatically cleared
   - Prevents database bloat from accumulated reminder records

## Key Features

- ✅ **1-Hour Prior Notification**: Automatically sends reminder 1 hour before event
- ✅ **User-Specific**: Only notifies users who have active bookings
- ✅ **Duplicate Prevention**: Tracks scheduled reminders to prevent duplicate notifications
- ✅ **Periodic Updates**: Checks every 10 minutes for new bookings needing reminders
- ✅ **Database Tracking**: Maintains history of reminder scheduling
- ✅ **Cleanup**: Automatically removes old reminders to optimize database

## Database Schema Changes

- **Version 4 → 5**: Added `event_reminders` table
- **Migration**: Automatically creates the table if upgrading from previous versions

## Testing

To test the reminder system:

1. **Create an event** with a start time 1-2 hours in the future
2. **Book seats** for that event as different users
3. **Wait 10 minutes** for the periodic check to run (or restart the app)
4. **Verify** in the `event_reminders` table that reminders are created with status 'scheduled'
5. **Check notifications** 1 hour before event to see the reminder notification

### Database Queries for Testing

```sql
-- View all pending reminders
SELECT * FROM event_reminders WHERE status = 'scheduled';

-- View reminders for a specific event
SELECT * FROM event_reminders WHERE event_id = 'EVENT_ID';

-- View reminders for a specific user
SELECT * FROM event_reminders WHERE user_id = 'USER_ID';

-- View sent reminders
SELECT * FROM event_reminders WHERE status = 'sent';
```

## Configuration

### Reminder Timing
- **Default**: 1 hour before event start
- **To change**: Modify `Duration(hours: 1)` in `event_reminder_service.dart`

### Periodic Check Interval
- **Default**: Every 10 minutes
- **To change**: Modify `const Duration(minutes: 10)` in `app.dart`

### Upcoming Events Window
- **Default**: Events within 2 hours
- **To change**: Modify `const Duration(hours: 2)` in `event_reminder_service.dart`

## Error Handling

- Service gracefully handles missing plugins (web, early SDK versions)
- Database errors are logged but don't crash the app
- Invalid reminder times (in the past) are skipped
- Duplicate reminder detection prevents multiple notifications for same booking

## Performance Considerations

- Reminders are checked in background every 10 minutes
- Database queries use indexes on event_id, user_id, and ticket_id
- Old reminders are automatically cleaned up to prevent table bloat
- Notification scheduling is non-blocking and uses async/await

## Future Enhancements

1. **Custom Reminder Times**: Allow users to set custom reminder durations (30 min, 2 hours, etc.)
2. **Multiple Reminders**: Send multiple reminders at different intervals
3. **User Preferences**: Respect user notification preferences per event
4. **Push Notifications**: Integrate with backend for server-side reminder scheduling
5. **Reminder History**: Track which users received notifications and when
6. **Failed Reminder Retry**: Retry failed notifications with exponential backoff
