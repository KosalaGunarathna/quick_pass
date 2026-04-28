import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_bloc.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});
  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  List<EventEntity> _cachedEvents = [];

  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(EventLoadAll());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventEntity> _applyFilters(List<EventEntity> events) {
    final search = _searchTerm.trim().toLowerCase();
    if (search.isEmpty) return events;
    return events
        .where(
          (e) =>
              e.title.toLowerCase().contains(search) ||
              e.description.toLowerCase().contains(search) ||
              e.location.toLowerCase().contains(search),
        )
        .toList();
  }

  String _userName(BuildContext context) {
  final state = context.watch<AuthBloc>().state;
  return state is AuthAuthenticated ? state.user.name : 'Guest';
}

  String _userInitials(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated && state.user.name.isNotEmpty) {
      final parts = state.user.name.split(' ');
      return parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : state.user.name[0].toUpperCase();
    }
    return 'JD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: BlocConsumer<EventBloc, EventState>(
          listener: (context, state) {
            if (state is EventCreated ||
                state is EventUpdated ||
                state is EventDeleted) {
              context.read<EventBloc>().add(EventLoadAll());
            }
          },
          builder: (context, state) {
            if (state is EventsLoaded) _cachedEvents = state.events;

            if (state is EventLoading && _cachedEvents.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EventError) {
              return Center(child: Text(state.message));
            }

            return _buildEventDashboard(context, _cachedEvents);
          },
        ),
      ),
    );
  }

  Widget _buildEventDashboard(BuildContext context, List<EventEntity> events) {
    final filteredEvents = _applyFilters(events);

    return RefreshIndicator(
      onRefresh: () async => context.read<EventBloc>().add(EventLoadAll()),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hello, ${_userName(context)}',
            
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF1F5FA6),
                        child: Text(
                          _userInitials(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 28),
                  const Text(
                    'All Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          _buildEventSliver(events, filteredEvents),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchTerm = value),
        decoration: InputDecoration(
          hintText: 'Search events, venues, organizers...',
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF5F7FB),
        ),
      ),
    );
  }

  Widget _buildEventSliver(
    List<EventEntity> allEvents,
    List<EventEntity> filtered,
  ) {
    if (allEvents.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No events yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No matching events found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: EventCard(event: filtered[index]),
        ),
        childCount: filtered.length,
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventEntity event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(event.eventDate);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () async {
          await context.push('/event/${event.id}');
          if (!context.mounted) return;
          context.read<EventBloc>().add(EventLoadAll());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: event.imageUrl != null
                    ? Image.network(
                        event.imageUrl!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbnail(),
                      )
                    : _thumbnail(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatted,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          event.ticketPrice == 0
                              ? 'Free'
                              : '\$${event.ticketPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F5FA6),
                          ),
                        ),
                        _seatsBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() => Container(
    width: 88,
    height: 88,
    color: const Color(0xFFE8EAF6),
    child: const Icon(Icons.event, color: Color(0xFF3F51B5), size: 32),
  );

  Widget _seatsBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: event.hasAvailableSeats
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      event.hasAvailableSeats
          ? '${event.availableSeats} seats available'
          : 'Sold out',
      style: TextStyle(
        color: event.hasAvailableSeats
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
