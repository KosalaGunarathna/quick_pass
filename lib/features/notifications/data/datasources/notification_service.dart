import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../shared/local_db/database_helper.dart';
import 'notification_local_datasource.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationLocalDatasource _store = NotificationLocalDatasource(
    db: DatabaseHelper.instance,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(settings);
    tz.initializeTimeZones();
    await _store.ensureTable();
    _initialized = true;
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
  }) async {
    if (!_initialized) await init();

    if (kIsWeb) return;

    final reminderTime = eventDate.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        eventId.hashCode,
        'Upcoming Event Reminder',
        '$eventTitle starts in 1 hour',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders',
            'Event Reminders',
            channelDescription: 'Reminder notifications before events',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on UnimplementedError {
      return;
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> sendNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    if (kIsWeb) return;

    try {
      await _store.saveNotification(title: title, body: body);
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general_notifications',
            'General Notifications',
            channelDescription: 'Organizer and app notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await init();
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
      await _store.clearAll();
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }
}
