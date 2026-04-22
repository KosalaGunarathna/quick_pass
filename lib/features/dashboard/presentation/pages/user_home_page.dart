import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../events/presentation/bloc/event_bloc.dart';
import '../../../events/presentation/pages/event_list_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../tickets/presentation/bloc/ticket_bloc.dart';
import '../../../tickets/presentation/pages/my_tickets_page.dart';
import 'organizer_dashboard_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(EventLoadAll());
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<TicketBloc>().add(TicketLoadMine(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const EventListPage(),
      const MyTicketsPage(),
      const NotificationsPage(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Events'),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number),
            label: 'My Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
