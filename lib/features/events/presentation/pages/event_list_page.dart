import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_bloc.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});
  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(EventLoadAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventCreated ||
              state is EventUpdated ||
              state is EventDeleted) {
            context.read<EventBloc>().add(EventLoadAll());
          }
        },
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EventError) {
            return Center(child: Text(state.message));
          }
          if (state is EventsLoaded) {
            if (state.events.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No events yet', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<EventBloc>().add(EventLoadAll()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.events.length,
                itemBuilder: (_, i) => EventCard(event: state.events[i]),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventEntity event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event.date);
    final formatted = date != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(date)
        : event.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await context.push('/event/${event.id}');
          if (!context.mounted) return;
          context.read<EventBloc>().add(EventLoadAll());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.deepPurple.shade100,
                  child: const Icon(
                    Icons.image,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                ),
              )
            else
              Container(
                height: 160,
                color: Colors.deepPurple.shade100,
                child: const Center(
                  child: Icon(Icons.event, size: 48, color: Colors.deepPurple),
                ),
              ),
            if (event.isFeatured)
              Container(
                width: double.infinity,
                color: Colors.amber,
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                child: const Text(
                  'FEATURED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formatted,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.price == 0
                            ? 'Free'
                            : '\$${event.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: event.hasAvailableSeats
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: event.hasAvailableSeats
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          event.hasAvailableSeats
                              ? '${event.availableSeats} seats left'
                              : 'Sold Out',
                          style: TextStyle(
                            fontSize: 12,
                            color: event.hasAvailableSeats
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
