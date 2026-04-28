import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../notifications/data/datasources/notification_service.dart';
import '../../../tickets/presentation/bloc/ticket_bloc.dart';
import '../../../tickets/domain/entities/event_booking_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/seat_entity.dart';
import '../bloc/event_bloc.dart';

class OrganizerEventViewPage extends StatefulWidget {
  final EventEntity event;
  final String organizerId;

  const OrganizerEventViewPage({
    super.key,
    required this.event,
    required this.organizerId,
  });

  @override
  State<OrganizerEventViewPage> createState() => _OrganizerEventViewPageState();
}

class _OrganizerEventViewPageState extends State<OrganizerEventViewPage> {
  EventBookingEntity? _selectedBooking;

  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(SeatsLoad(widget.event.id));
    context.read<TicketBloc>().add(TicketLoadByEvent(widget.event.id));
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final organizerId = widget.organizerId;
    final formattedDate = DateFormat(
      'EEE, MMM dd yyyy • hh:mm a',
    ).format(event.eventDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Color(0xFF1F5FA6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _showSendNotificationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(
              '/organizer/event-update',
              extra: {'event': event, 'organizerId': organizerId},
            ),
          ),
        ],
      ),
      body: BlocListener<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventDeleted && context.mounted) {
            context.read<EventBloc>().add(EventLoadByOrganizer(organizerId));
            context.pop();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    event.imageUrl!,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 210,
                      color: Color(0xFF1F5FA6),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 48),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.calendar_today, formattedDate),
              _infoRow(Icons.location_on, event.location),
              _infoRow(Icons.category, event.category),
              _infoRow(
                Icons.event_seat,
                '${event.availableSeats} / ${event.totalSeats} seats available',
              ),
              _infoRow(
                Icons.attach_money,
                event.ticketPrice == 0
                    ? 'Free'
                    : '\$${event.ticketPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(event.description, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/organizer/event-update',
                        extra: {'event': event, 'organizerId': organizerId},
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Update'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed =
                            await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete Event'),
                                content: const Text(
                                  'Delete this event permanently?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!confirmed || !context.mounted) return;
                        context.read<EventBloc>().add(EventDelete(event.id));
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.event_seat, color: Color(0xFF1F5FA6)),
                  const SizedBox(width: 8),
                  Text(
                    'Seat Status (Organizer View)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLegend(),
              const SizedBox(height: 12),
              BlocBuilder<EventBloc, EventState>(
                builder: (context, eventState) {
                  if (eventState is EventLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (eventState is EventError) {
                    return Text(
                      'Failed to load seats: ${eventState.message}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                  if (eventState is! SeatsLoaded) {
                    return const SizedBox();
                  }

                  return BlocBuilder<TicketBloc, TicketState>(
                    builder: (context, ticketState) {
                      if (ticketState is TicketLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (ticketState is TicketError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Failed to load bookings: ${ticketState.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final bookings = ticketState is EventBookingsLoaded
                          ? ticketState.bookings
                          : <EventBookingEntity>[];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSeatGrid(eventState.seats, bookings),
                          const SizedBox(height: 14),
                          _buildSelectedSeatDetails(),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(0xFF1F5FA6)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _SeatLegendItem(color: Color(0xFF43A047), label: 'Available'),
        _SeatLegendItem(color: Color(0xFFE53935), label: 'Unavailable'),
        _SeatLegendItem(color: Color(0xFF1E88E5), label: 'Selected'),
      ],
    );
  }

  Widget _buildSeatGrid(
    List<SeatEntity> seats,
    List<EventBookingEntity> bookings,
  ) {
    if (seats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('No seats created for this event yet.'),
      );
    }

    final bookingBySeat = <String, EventBookingEntity>{
      for (final booking in bookings) booking.seatId: booking,
    };

    final grouped = <String, List<SeatEntity>>{};
    for (final seat in seats) {
      grouped.putIfAbsent(seat.rowLabel, () => []).add(seat);
    }

    final rowKeys = grouped.keys.toList()..sort();
    for (final key in rowKeys) {
      grouped[key]!.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    }

    return Column(
      children: rowKeys.map((row) {
        final rowSeats = grouped[row]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  row,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: rowSeats.map((seat) {
                    final booking = bookingBySeat[seat.id];
                    final isUnavailable =
                        booking != null ||
                        seat.status != 'available' ||
                        !seat.isAvailable;
                    final isSelected = _selectedBooking?.seatId == seat.id;
                    final color = isSelected
                        ? const Color(0xFF1E88E5)
                        : isUnavailable
                        ? const Color(0xFFE53935)
                        : const Color(0xFF43A047);

                    return GestureDetector(
                      onTap: () {
                        if (!isUnavailable || booking == null) {
                          setState(() => _selectedBooking = null);
                          return;
                        }
                        setState(() => _selectedBooking = booking);
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${seat.seatNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedSeatDetails() {
    final booking = _selectedBooking;
    if (booking == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Tap a selected/unavailable seat to view attendee details.',
        ),
      );
    }

    return _bookingCard(booking);
  }

  Widget _bookingCard(EventBookingEntity booking) {
    final bookedAt = DateTime.tryParse(booking.bookedAt);
    final bookedAtText = bookedAt == null
        ? booking.bookedAt
        : DateFormat('dd MMM yyyy, hh:mm a').format(bookedAt);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seat ${booking.seatLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: booking.isActive
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: booking.isActive
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Member: ${booking.userName}'),
            Text('Email: ${booking.userEmail}'),
            const SizedBox(height: 4),
            Text(
              'Booked at: $bookedAtText',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSendNotificationDialog() async {
    final titleCtrl = TextEditingController(text: widget.event.title);
    final bodyCtrl = TextEditingController(
      text: 'Update for ${widget.event.title}',
    );
    final formKey = GlobalKey<FormState>();

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Notification'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Message is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (shouldSend != true || !mounted) return;

    await NotificationService.instance.sendNotification(
      id: widget.event.id.hashCode,
      title: titleCtrl.text.trim(),
      body: bodyCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification sent')));
  }
}

class _SeatLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _SeatLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
