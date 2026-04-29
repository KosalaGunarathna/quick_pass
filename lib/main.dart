import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/di/injection_container.dart';
import 'app.dart';
import 'features/notifications/data/datasources/notification_service.dart';
import 'features/notifications/data/datasources/event_reminder_service.dart';
import 'features/notifications/domain/usecases/schedule_event_reminders_use_case.dart';
import 'shared/local_db/database_helper.dart';
import 'shared/local_db/tables/events_table.dart';
import 'shared/local_db/tables/seats_table.dart';
import 'shared/local_db/tables/tickets_table.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await NotificationService.instance.init();
  await EventReminderService.instance.init();
  await initDependencies();
  await _cleanupLegacyEventOne();

  // Schedule reminders for upcoming events
  await _scheduleInitialReminders();

  runApp(const SmartEventApp());
}

Future<void> _cleanupLegacyEventOne() async {
  final db = DatabaseHelper.instance;
  final rows = await db.query(EventsTable.tableName);
  final legacyEvents = rows.where((row) {
    final title = (row[EventsTable.title] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return title == 'event 1';
  }).toList();

  for (final event in legacyEvents) {
    final eventId = (event[EventsTable.id] ?? '').toString();
    if (eventId.isEmpty) continue;

    await db.delete(
      TicketsTable.tableName,
      where: '${TicketsTable.eventId} = ?',
      whereArgs: [eventId],
    );
    await db.delete(
      SeatsTable.tableName,
      where: '${SeatsTable.eventId} = ?',
      whereArgs: [eventId],
    );
    await db.delete(
      EventsTable.tableName,
      where: '${EventsTable.id} = ?',
      whereArgs: [eventId],
    );
  }
}

Future<void> _scheduleInitialReminders() async {
  try {
    final useCase = ScheduleEventRemindersUseCase(
      EventReminderService.instance,
    );
    await useCase.call();
  } catch (e) {
    debugPrint('Error scheduling initial reminders: $e');
  }
}
