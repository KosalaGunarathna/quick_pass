import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_bloc.dart';
import '../widgets/event_location_map_widget.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(EventLoadById(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        if (state is EventLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Event Details'),
              backgroundColor: Color(0xFF1F5FA6),
              foregroundColor: Colors.white,
              leading: const BackButton(),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is EventDetailLoaded) {
          return Scaffold(body: _buildDetail(context, state.event));
        }
        if (state is EventError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Event Details'),
              backgroundColor: Color(0xFF1F5FA6),
              foregroundColor: Colors.white,
              leading: const BackButton(),
            ),
            body: Center(child: Text(state.message)),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Event Details'),
            backgroundColor: Color(0xFF1F5FA6),
            foregroundColor: Colors.white,
            leading: const BackButton(),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context, EventEntity event) {
    final date = DateTime.tryParse(event.date);
    final formatted = date != null
        ? DateFormat('EEEE, MMM dd yyyy • hh:mm a').format(date)
        : event.date;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 20,
          pinned: true,
          backgroundColor: Color(0xFF1F5FA6),
          foregroundColor: Colors.white,
          leading: BackButton(onPressed: () => context.pop()),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              event.title,
              style: const TextStyle(fontSize: 20, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: event.imageUrl != null
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Color(0xFF1F5FA6)),
                  )
                : Container(color: Color(0xFF1F5FA6)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.calendar_today, formatted),
                const SizedBox(height: 10),
                _infoRow(Icons.location_on, event.venue),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.event_seat,
                  '${event.availableSeats} / ${event.totalSeats} seats available',
                ),
                const SizedBox(height: 20),
                Text('About', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                if (event.hasLocationCoordinates) ...[
                  Text(
                    'Event Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  EventLocationMapWidget(
                    latitude: event.latitude!,
                    longitude: event.longitude!,
                    locationName: event.venue,
                    height: 250,
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: event.hasAvailableSeats
                        ? () async {
                            await context.push('/book/${event.id}');
                            if (!context.mounted) return;
                            context.read<EventBloc>().add(
                              EventLoadById(widget.eventId),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1F5FA6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      event.hasAvailableSeats
                          ? 'Book Ticket — \$${event.price.toStringAsFixed(2)}'
                          : 'Sold Out',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Color(0xFF1F5FA6)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    ],
  );
}
