import 'package:uuid/uuid.dart';
import '../../../../shared/local_db/database_helper.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../../../shared/local_db/tables/events_table.dart';
import '../../../../shared/local_db/tables/seats_table.dart';
import '../../../../shared/local_db/tables/tickets_table.dart';
import '../../../../shared/local_db/tables/users_table.dart';
import '../../../notifications/data/datasources/notification_service.dart';
import '../../domain/entities/event_booking_entity.dart';

// ── Model ──────────────────────────────────────────────────────────────────

class TicketModel extends TicketEntity {
  const TicketModel({
    required super.id,
    required super.eventId,
    required super.userId,
    required super.seatId,
    required super.qrData,
    required super.status,
    required super.bookedAt,
    super.seatNumber,
    super.rawLabel,
    super.userName,
    super.userEmail,
    super.userContact,
  });

  factory TicketModel.fromMap(Map<String, dynamic> m) => TicketModel(
    id: m['id'],
    eventId: m[TicketsTable.eventId],
    userId: m[TicketsTable.userId],
    seatId: m[TicketsTable.seatId],
    qrData: m[TicketsTable.qrData],
    status: m[TicketsTable.status],
    bookedAt: m[TicketsTable.bookedAt],
    seatNumber: (m['seat_number'] ?? m['seatNumber'])?.toString(),
    rawLabel: (m['seat_row_label'] ?? m['seat_row_label'] ?? m['row_label'])
        ?.toString(),
    userName: _firstNonEmpty(m, ['user_name', 'booked_user_name', 'name']),
    userEmail: _firstNonEmpty(m, ['user_email', 'booked_user_email', 'email']),
    userContact: _firstNonEmpty(m, [
      'user_contact',
      'booked_user_contact',
      'contact_number',
    ]),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    TicketsTable.eventId: eventId,
    TicketsTable.userId: userId,
    TicketsTable.seatId: seatId,
    TicketsTable.qrData: qrData,
    TicketsTable.status: status,
    TicketsTable.bookedAt: bookedAt,
  };
}

String? _firstNonEmpty(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k)) {
      final v = m[k];
      if (v != null) {
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
    }
  }
  return null;
}

// ── Datasource ─────────────────────────────────────────────────────────────

class TicketLocalDatasource {
  TicketLocalDatasource({required this.db});

  final DatabaseHelper db;

  // Shared SELECT + JOINs for ticket queries
  static const String _ticketSelect =
      '''
    SELECT
      t.${TicketsTable.id} AS id,
      t.${TicketsTable.eventId},
      t.${TicketsTable.userId},
      t.${TicketsTable.seatId},
      t.${TicketsTable.qrData},
      t.${TicketsTable.status},
      t.${TicketsTable.bookedAt},
      s.${SeatsTable.rowLabel} AS seat_row_label,
      s.${SeatsTable.seatNumber} AS seat_number,
      u.${UsersTable.name} AS user_name,
      u.${UsersTable.email} AS user_email,
      u.${UsersTable.contactNumber} AS user_contact
    FROM ${TicketsTable.tableName} t
    INNER JOIN ${SeatsTable.tableName} s ON s.${SeatsTable.id} = t.${TicketsTable.seatId}
    INNER JOIN ${UsersTable.tableName} u ON u.${UsersTable.id} = t.${TicketsTable.userId}
  ''';

  Future<List<Map<String, dynamic>>> _queryTicketRows(
    String where,
    List<Object?> args,
  ) async {
    final results = await db.rawQuery('$_ticketSelect WHERE $where', args);
    return results;
  }

  // ── Public methods ────────────────────────────────────────────────────────

  Future<List<TicketModel>> getTicketsByUser(String userId) async {
    final rows = await _queryTicketRows(
      't.${TicketsTable.userId} = ? ORDER BY t.${TicketsTable.bookedAt} DESC',
      [userId],
    );
    return rows.map((r) => TicketModel.fromMap(r)).toList();
  }

  Future<TicketModel?> getTicketById(String id) async {
    final results = await _queryTicketRows('t.${TicketsTable.id} = ?', [id]);
    if (results.isEmpty) return null;
    final row = Map<String, dynamic>.from(results.first);
    // if user fields missing or empty, try to fetch from users table directly
    final maybeUserName = _firstNonEmpty(row, [
      'user_name',
      'booked_user_name',
      'name',
    ]);
    if (maybeUserName == null) {
      final userId = row[TicketsTable.userId]?.toString();
      if (userId != null && userId.isNotEmpty) {
        final userRows = await db.query(
          UsersTable.tableName,
          where: '\${UsersTable.id} = ?',
          whereArgs: [userId],
        );
        if (userRows.isNotEmpty) {
          final u = userRows.first;
          row['user_name'] = u[UsersTable.name];
          row['user_email'] = u[UsersTable.email];
          row['user_contact'] = u[UsersTable.contactNumber];
        }
      }
    }
    return TicketModel.fromMap(row);
  }

  Future<TicketModel?> validateTicket(String qrData) async {
    final results = await _queryTicketRows('t.${TicketsTable.qrData} = ?', [
      qrData,
    ]);
    if (results.isEmpty) return null;
    final row = Map<String, dynamic>.from(results.first);
    final maybeUserName = _firstNonEmpty(row, [
      'user_name',
      'booked_user_name',
      'name',
    ]);
    if (maybeUserName == null) {
      final userId = row[TicketsTable.userId]?.toString();
      if (userId != null && userId.isNotEmpty) {
        final userRows = await db.query(
          UsersTable.tableName,
          where: '\${UsersTable.id} = ?',
          whereArgs: [userId],
        );
        if (userRows.isNotEmpty) {
          final u = userRows.first;
          row['user_name'] = u[UsersTable.name];
          row['user_email'] = u[UsersTable.email];
          row['user_contact'] = u[UsersTable.contactNumber];
        }
      }
    }
    return TicketModel.fromMap(row);
  }

  Future<void> markTicketUsed(String ticketId) => db.update(
    TicketsTable.tableName,
    {TicketsTable.status: 'used'},
    where: '${TicketsTable.id} = ?',
    whereArgs: [ticketId],
  );

  Future<List<EventBookingEntity>> getBookingsByEvent(String eventId) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        t.${TicketsTable.id} AS ticket_id,
        t.${TicketsTable.seatId} AS seat_id,
        t.${TicketsTable.status} AS ticket_status,
        t.${TicketsTable.bookedAt} AS ticket_booked_at,
        s.${SeatsTable.rowLabel} AS seat_row_label,
        s.${SeatsTable.seatNumber} AS seat_number,
        u.${UsersTable.id} AS booked_user_id,
        u.${UsersTable.name} AS booked_user_name,
        u.${UsersTable.email} AS booked_user_email
      FROM ${TicketsTable.tableName} t
      INNER JOIN ${SeatsTable.tableName} s ON s.${SeatsTable.id} = t.${TicketsTable.seatId}
      INNER JOIN ${UsersTable.tableName} u ON u.${UsersTable.id} = t.${TicketsTable.userId}
      WHERE t.${TicketsTable.eventId} = ?
      ORDER BY s.${SeatsTable.rowLabel} ASC, s.${SeatsTable.seatNumber} ASC
      ''',
      [eventId],
    );

    return rows.map((row) {
      final label = '${row['seat_row_label'] ?? ''}${row['seat_number'] ?? ''}';
      return EventBookingEntity(
        ticketId: '${row['ticket_id'] ?? ''}',
        seatId: '${row['seat_id'] ?? ''}',
        seatLabel: label,
        userId: '${row['booked_user_id'] ?? ''}',
        userName: '${row['booked_user_name'] ?? 'Unknown'}',
        userEmail: '${row['booked_user_email'] ?? ''}',
        status: '${row['ticket_status'] ?? 'active'}',
        bookedAt: '${row['ticket_booked_at'] ?? ''}',
      );
    }).toList();
  }

  Future<TicketModel> bookTicket({
    required String eventId,
    required String userId,
    required String seatId,
  }) async {
    final id = const Uuid().v4();

    // Fetch user details
    final userRows = await db.query(
      UsersTable.tableName,
      where: '${UsersTable.id} = ?',
      whereArgs: [userId],
    );
    final user = userRows.isNotEmpty ? userRows.first : null;

    final ticket = TicketModel(
      id: id,
      eventId: eventId,
      userId: userId,
      seatId: seatId,
      qrData: 'TICKET:$id:$eventId:$seatId',
      status: 'active',
      bookedAt: DateTime.now().toIso8601String(),
      userName: user?[UsersTable.name]?.toString(),
      userEmail: user?[UsersTable.email]?.toString(),
      userContact: user?[UsersTable.contactNumber]?.toString(),
    );

    await db.insert(TicketsTable.tableName, ticket.toMap());

    // Mark seat as booked
    await db.update(
      SeatsTable.tableName,
      {SeatsTable.status: 'booked', SeatsTable.ticketId: id},
      where: '${SeatsTable.id} = ?',
      whereArgs: [seatId],
    );

    // Decrement available seats & schedule notification
    final eventRows = await db.query(
      EventsTable.tableName,
      where: '${EventsTable.id} = ?',
      whereArgs: [eventId],
    );
    final event = eventRows.isNotEmpty ? eventRows.first : null;
    if (event != null) {
      final available =
          int.tryParse('${event[EventsTable.availableSeats] ?? 0}') ?? 0;
      await db.update(
        EventsTable.tableName,
        {EventsTable.availableSeats: available > 0 ? available - 1 : 0},
        where: '${EventsTable.id} = ?',
        whereArgs: [eventId],
      );

      final date = DateTime.tryParse('${event[EventsTable.eventDate] ?? ''}');
      if (date != null) {
        await NotificationService.instance.scheduleEventReminder(
          eventId: eventId,
          eventTitle: (event[EventsTable.title] ?? 'Event').toString(),
          eventDate: date,
        );
      }
    }

    return ticket;
  }
}
