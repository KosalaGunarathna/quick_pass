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
  final List<String> _categories = [
    'All Events',
    'Conferences',
    'Workshops',
    'Concerts',
  ];
  String _selectedCategory = 'All Events';
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
    return events.where((event) {
      final matchesCategory =
          _selectedCategory == 'All Events' ||
          event.category.toLowerCase() == _selectedCategory.toLowerCase();
      final search = _searchTerm.trim().toLowerCase();
      final matchesSearch =
          search.isEmpty ||
          event.title.toLowerCase().contains(search) ||
          event.description.toLowerCase().contains(search) ||
          event.location.toLowerCase().contains(search);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildEventDashboard(BuildContext context, List<EventEntity> events) {
    final filteredEvents = _applyFilters(events);
    final featuredEvents = events.where((e) => e.isFeatured).toList();

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _userName(context),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                  Container(
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
                      onChanged: (value) => setState(() {
                        _searchTerm = value;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Search events, venues, organizers...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _selectedCategory = category;
                          }),
                          selectedColor: const Color(0xFF1F5FA6),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Featured Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: featuredEvents.isEmpty
                        ? const Center(
                            child: Text(
                              'No featured events available.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: featuredEvents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (_, index) {
                              return FeaturedEventCard(
                                event: featuredEvents[index],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Browse Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (events.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: const Center(
                child: Text(
                  'No events yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else if (filteredEvents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: const Center(
                child: Text(
                  'No matching events found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((_, index) {
                final event = filteredEvents[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: EventCard(event: event),
                );
              }, childCount: filteredEvents.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
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
            if (state is EventLoading && _cachedEvents.isNotEmpty) {
              return _buildEventDashboard(context, _cachedEvents);
            }
            if (state is EventLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EventDetailLoaded && _cachedEvents.isNotEmpty) {
              return _buildEventDashboard(context, _cachedEvents);
            }
            if (state is EventError) {
              return Center(child: Text(state.message));
            }
            if (state is EventsLoaded) {
              _cachedEvents = state.events;
              final filteredEvents = _applyFilters(state.events);
              final featuredEvents = state.events
                  .where((e) => e.isFeatured)
                  .toList();

              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<EventBloc>().add(EventLoadAll()),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome back,',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _userName(context),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                            Container(
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
                                onChanged: (value) => setState(() {
                                  _searchTerm = value;
                                }),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search events, venues, organizers...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FB),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, index) {
                                  final category = _categories[index];
                                  final isSelected =
                                      category == _selectedCategory;
                                  return ChoiceChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (_) => setState(() {
                                      _selectedCategory = category;
                                    }),
                                    selectedColor: const Color(0xFF1F5FA6),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Featured Events',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: featuredEvents.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No featured events available.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: featuredEvents.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (_, index) {
                                        return FeaturedEventCard(
                                          event: featuredEvents[index],
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Browse Events',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.events.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: const Center(
                          child: Text(
                            'No events yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else if (filteredEvents.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: const Center(
                          child: Text(
                            'No matching events found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((_, index) {
                          final event = filteredEvents[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: EventCard(event: event),
                          );
                        }, childCount: filteredEvents.length),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  String _userName(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.name;
    }
    return 'Guest';
  }

  String _userInitials(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.name.isNotEmpty) {
      final split = authState.user.name.split(' ');
      if (split.length >= 2) {
        return '${split[0][0]}${split[1][0]}'.toUpperCase();
      }
      return authState.user.name.substring(0, 1).toUpperCase();
    }
    return 'JD';
  }
}

class FeaturedEventCard extends StatelessWidget {
  final EventEntity event;
  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(event.eventDate);
    return InkWell(
      onTap: () async {
        await context.push('/event/${event.id}');
        if (!context.mounted) return;
        context.read<EventBloc>().add(EventLoadAll());
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: event.imageUrl != null
                  ? Image.network(
                      event.imageUrl!,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: const Color(0xFFE8EAF6),
                        child: const Icon(
                          Icons.image,
                          size: 52,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                    )
                  : Container(
                      height: 140,
                      color: const Color(0xFFE8EAF6),
                      child: const Center(
                        child: Icon(
                          Icons.event,
                          size: 52,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        color: Color(0xFF1F5FA6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formattedDate,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.ticketPrice == 0
                            ? 'Free'
                            : 'LKR ${event.ticketPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: event.hasAvailableSeats
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.hasAvailableSeats
                              ? '${event.availableSeats} seats available'
                              : 'Sold out',
                          style: TextStyle(
                            color: event.hasAvailableSeats
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                        errorBuilder: (_, __, ___) => Container(
                          width: 88,
                          height: 88,
                          color: const Color(0xFFE8EAF6),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF3F51B5),
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        width: 88,
                        height: 88,
                        color: const Color(0xFFE8EAF6),
                        child: const Icon(
                          Icons.event,
                          color: Color(0xFF3F51B5),
                          size: 32,
                        ),
                      ),
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
                              : 'LKR ${event.ticketPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F5FA6),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
                        ),
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
}
