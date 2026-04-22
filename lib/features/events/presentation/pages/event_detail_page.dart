import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_bloc.dart';

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
    return Scaffold(
      body: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventDetailLoaded) {
            return _buildDetail(context, state.event);
          }
          if (state is EventError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
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
          expandedHeight: 220,
          pinned: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: BackButton(onPressed: () => context.pop()),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              event.title,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: event.imageUrl != null
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.deepPurple.shade700),
                  )
                : Container(color: Colors.deepPurple.shade700),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: event.hasAvailableSeats
                        ? () => context.push('/book/${event.id}')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
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
      Icon(icon, size: 18, color: Colors.deepPurple),
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
