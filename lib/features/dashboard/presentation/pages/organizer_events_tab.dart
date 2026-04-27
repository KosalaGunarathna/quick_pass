import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/bloc/event_bloc.dart';

class OrganizerEventsTab extends StatefulWidget {
  final String organizerId;

  const OrganizerEventsTab({required this.organizerId, super.key});

  @override
  State<OrganizerEventsTab> createState() => _OrganizerEventsTabState();
}

class _OrganizerEventsTabState extends State<OrganizerEventsTab> {
  List<EventEntity> _cachedEvents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventCreated ||
              state is EventUpdated ||
              state is EventDeleted) {
            context.read<EventBloc>().add(
              EventLoadByOrganizer(widget.organizerId),
            );
          }
        },
        builder: (context, state) {
          if (state is EventLoading && _cachedEvents.isNotEmpty) {
            return _buildDashboard(context, _cachedEvents);
          }
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventDetailLoaded && _cachedEvents.isNotEmpty) {
            return _buildDashboard(context, _cachedEvents);
          }
          if (state is SeatsLoaded && _cachedEvents.isNotEmpty) {
            return _buildDashboard(context, _cachedEvents);
          }
          if (state is EventsLoaded) {
            _cachedEvents = state.events;
            return _buildDashboard(context, state.events);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<EventEntity> events) {
    final organizer = context.read<AuthBloc>().state;
    final name = organizer is AuthAuthenticated
        ? organizer.user.name
        : 'Organizer';
    final activeEvents = events.length;
    final totalBookings = events.fold<int>(
      0,
      (sum, event) => sum + (event.totalSeats - event.availableSeats),
    );
    final totalSeats = events.fold<int>(
      0,
      (sum, event) => sum + event.totalSeats,
    );
    final totalSold = events.fold<int>(
      0,
      (sum, event) => sum + (event.totalSeats - event.availableSeats),
    );
    final revenue = events.fold<double>(
      0,
      (sum, event) =>
          sum + (event.ticketPrice * (event.totalSeats - event.availableSeats)),
    );
    final avgAttendance = totalSeats > 0
        ? ((totalSold / totalSeats) * 100).round()
        : 0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F5FA6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Organizer Dashboard',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'O',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildMetricCard(
                      title: 'Active Events',
                      value: '$activeEvents',
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      title: 'Total Bookings',
                      value: '$totalBookings',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetricCard(
                      title: 'Revenue (MTD)',
                      value: 'LKR ${revenue.round()}',
                      valueColor: const Color(0xFF1F5FA6),
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      title: 'Avg Attendance',
                      value: '$avgAttendance%',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/create-event');
                          if (!context.mounted) return;
                          context.read<EventBloc>().add(
                            EventLoadByOrganizer(widget.organizerId),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F5FA6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/scan'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Tickets'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('View all')),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: OrganizerEventCard(
                event: events[index],
                organizerId: widget.organizerId,
              ),
            );
          }, childCount: events.length),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    Color valueColor = Colors.black,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrganizerEventCard extends StatelessWidget {
  final EventEntity event;
  final String organizerId;

  const OrganizerEventCard({
    required this.event,
    required this.organizerId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ticketsSold = event.totalSeats - event.availableSeats;
    final progress = event.totalSeats > 0
        ? ticketsSold / event.totalSeats
        : 0.0;
    final isDraft = ticketsSold == 0;
    final statusLabel = isDraft ? 'Draft' : 'Live';
    final statusColor = isDraft
        ? Colors.orange.shade100
        : Colors.green.shade100;
    final statusTextColor = isDraft
        ? Colors.orange.shade700
        : Colors.green.shade700;
    final dateText = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(event.eventDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dateText,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              event.location,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  color: isDraft ? Colors.orange : Colors.green,
                  backgroundColor: Colors.transparent,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$ticketsSold / ${event.totalSeats} tickets sold',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'LKR ${event.ticketPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F5FA6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await context.push(
                        '/organizer/event-update',
                        extra: {'event': event, 'organizerId': organizerId},
                      );
                      if (!context.mounted) return;
                      context.read<EventBloc>().add(
                        EventLoadByOrganizer(organizerId),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F5FA6),
                      side: const BorderSide(color: Color(0xFF1F5FA6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isDraft ? 'Continue Setup' : 'Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isDraft) {
                        final confirmed =
                            await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Event'),
                                content: const Text(
                                  'Are you sure you want to delete this event?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!confirmed || !context.mounted) return;
                        context.read<EventBloc>().add(EventDelete(event.id));
                        await Future<void>.delayed(
                          const Duration(milliseconds: 250),
                        );
                        if (!context.mounted) return;
                        context.read<EventBloc>().add(
                          EventLoadByOrganizer(organizerId),
                        );
                        return;
                      }

                      await context.push(
                        '/organizer/event-view',
                        extra: {'event': event, 'organizerId': organizerId},
                      );
                      if (!context.mounted) return;
                      context.read<EventBloc>().add(
                        EventLoadByOrganizer(organizerId),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5FA6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isDraft ? 'Delete' : 'Analytics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
