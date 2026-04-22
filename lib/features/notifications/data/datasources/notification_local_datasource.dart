import 'package:uuid/uuid.dart';
import '../../../../shared/local_db/database_helper.dart';
import '../../../../shared/local_db/tables/notifications_table.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationLocalDatasource {
  final DatabaseHelper db;
  NotificationLocalDatasource({required this.db});

  Future<void> ensureTable() async {
    await db.database;
    await db.rawQuery(NotificationsTable.createSql);
  }

  Future<void> saveNotification({
    required String title,
    required String body,
    String? eventId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.insert(NotificationsTable.tableName, {
      NotificationsTable.id: const Uuid().v4(),
      NotificationsTable.title: title,
      NotificationsTable.body: body,
      NotificationsTable.eventId: eventId,
      NotificationsTable.createdAt: now,
    });
  }

  Future<List<NotificationEntity>> getAll() async {
    final rows = await db.query(
      NotificationsTable.tableName,
      orderBy: '${NotificationsTable.createdAt} DESC',
    );
    return rows.map((row) {
      return NotificationEntity(
        id: (row[NotificationsTable.id] ?? '').toString(),
        title: (row[NotificationsTable.title] ?? '').toString(),
        body: (row[NotificationsTable.body] ?? '').toString(),
        eventId: row[NotificationsTable.eventId]?.toString(),
        createdAt: (row[NotificationsTable.createdAt] ?? '').toString(),
      );
    }).toList();
  }

  Future<void> clearAll() async {
    await db.delete(
      NotificationsTable.tableName,
      where: '1=1',
      whereArgs: const [],
    );
  }
}
