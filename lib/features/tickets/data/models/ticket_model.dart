import 'package:uuid/uuid.dart';
import '../../../../shared/local_db/database_helper.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../../../shared/local_db/tables/events_table.dart';
import '../../../../shared/local_db/tables/seats_table.dart';
import '../../../../shared/local_db/tables/tickets_table.dart';
import '../../../../shared/local_db/tables/users_table.dart';
import '../../../notifications/data/datasources/notification_service.dart';
import '../../domain/entities/event_booking_entity.dart';

// Model
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
  });

  factory TicketModel.fromMap(Map<String, dynamic> m) => TicketModel(
    id: m['id'],
    eventId: m[TicketsTable.eventId],
    userId: m[TicketsTable.userId],
    seatId: m[TicketsTable.seatId],
    qrData: m[TicketsTable.qrData],
    status: m[TicketsTable.status],
    bookedAt: m[TicketsTable.bookedAt],
    seatNumber: m['seat_number'],
    rawLabel: m['seat_row_label'],
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

// Datasource
class TicketLocalDatasource {
  final DatabaseHelper db;
  TicketLocalDatasource({required this.db});

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
      INNER JOIN ${SeatsTable.tableName} s
        ON s.${SeatsTable.id} = t.${TicketsTable.seatId}
      INNER JOIN ${UsersTable.tableName} u
        ON u.${UsersTable.id} = t.${TicketsTable.userId}
      WHERE t.${TicketsTable.eventId} = ?
      ORDER BY s.${SeatsTable.rowLabel} ASC, s.${SeatsTable.seatNumber} ASC
      ''',
      [eventId],
    );

    return rows.map((row) {
      final rowLabel = (row['seat_row_label'] ?? '').toString();
      final seatNumber = (row['seat_number'] ?? '').toString();
      final seatLabel = '$rowLabel$seatNumber';
      return EventBookingEntity(
        ticketId: (row['ticket_id'] ?? '').toString(),
        seatId: (row['seat_id'] ?? '').toString(),
        seatLabel: seatLabel,
        userId: (row['booked_user_id'] ?? '').toString(),
        userName: (row['booked_user_name'] ?? 'Unknown').toString(),
        userEmail: (row['booked_user_email'] ?? '').toString(),
        status: (row['ticket_status'] ?? 'active').toString(),
        bookedAt: (row['ticket_booked_at'] ?? '').toString(),
      );
    }).toList();
  }

  Future<TicketModel> bookTicket({
    required String eventId,
    required String userId,
    required String seatId,
  }) async {
    final id = const Uuid().v4();
    final qrData = 'TICKET:$id:$eventId:$seatId';
    final ticket = TicketModel(
      id: id,
      eventId: eventId,
      userId: userId,
      seatId: seatId,
      qrData: qrData,
      status: 'active',
      bookedAt: DateTime.now().toIso8601String(),
    );
    await db.insert(TicketsTable.tableName, ticket.toMap());
    // Mark seat as booked
    await db.update(
      SeatsTable.tableName,
      {SeatsTable.status: 'booked', SeatsTable.ticketId: id},
      where: '${SeatsTable.id} = ?',
      whereArgs: [seatId],
    );
    final eventRows = await db.query(
      EventsTable.tableName,
      where: '${EventsTable.id} = ?',
      whereArgs: [eventId],
    );
    if (eventRows.isNotEmpty) {
      final currentAvailable =
          int.tryParse('${eventRows.first[EventsTable.availableSeats] ?? 0}') ??
          0;
      await db.update(
        EventsTable.tableName,
        {
          EventsTable.availableSeats: currentAvailable > 0
              ? currentAvailable - 1
              : 0,
        },
        where: '${EventsTable.id} = ?',
        whereArgs: [eventId],
      );
    }
    if (eventRows.isNotEmpty) {
      final event = eventRows.first;
      final title = (event[EventsTable.title] ?? 'Event').toString();
      final dateRaw = (event[EventsTable.eventDate] ?? '').toString();
      final date = DateTime.tryParse(dateRaw);
      if (date != null) {
        await NotificationService.instance.scheduleEventReminder(
          eventId: eventId,
          eventTitle: title,
          eventDate: date,
        );
      }
    }
    return ticket;
  }

  Future<List<TicketModel>> getTicketsByUser(String userId) async {
    final results = await db.query(
      TicketsTable.tableName,
      where: '${TicketsTable.userId} = ?',
      whereArgs: [userId],
      orderBy: '${TicketsTable.bookedAt} DESC',
    );
    return results.map((t) => TicketModel.fromMap(t)).toList();
  }

  Future<TicketModel?> getTicketById(String id) async {
    final results = await db.query(
      TicketsTable.tableName,
      where: '${TicketsTable.id} = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return TicketModel.fromMap(results.first);
  }

  Future<TicketModel?> validateTicket(String qrData) async {
    final results = await db.query(
      TicketsTable.tableName,
      where: '${TicketsTable.qrData} = ?',
      whereArgs: [qrData],
    );
    if (results.isEmpty) return null;
    return TicketModel.fromMap(results.first);
  }

  Future<void> markTicketUsed(String ticketId) async {
    await db.update(
      TicketsTable.tableName,
      {TicketsTable.status: 'used'},
      where: '${TicketsTable.id} = ?',
      whereArgs: [ticketId],
    );
  }
}
