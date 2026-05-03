import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/events/domain/entities/event_entity.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/organizer_home_page.dart';
import '../../features/dashboard/presentation/pages/user_home_page.dart';
import '../../features/events/presentation/pages/create_event_page.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/events/presentation/pages/organizer_event_view_page.dart';
import '../../features/events/presentation/pages/update_event_page.dart';
import '../../features/tickets/presentation/pages/booking_page.dart';
import '../../features/tickets/presentation/pages/my_tickets_page.dart';
import '../../features/qr_scanner/presentation/pages/qr_scanner_page.dart';
import '../../features/qr_scanner/presentation/pages/qr_result_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';



GoRouter buildRouter(AuthBloc authBloc) {
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        return authState.user.isOrganizer ? '/organizer' : '/home';
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (_, state) {
          final role = state.uri.queryParameters['role'] ?? 'user';
          return RegisterPage(initialRole: role);
        },
      ),
      // User and Organizer Home Pages
      GoRoute(path: '/home', builder: (_, __) => const UserHomePage()),
      GoRoute(
        path: '/organizer',
        builder: (_, __) => const OrganizerHomePage(),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (_, state) =>
            EventDetailPage(eventId: state.pathParameters['id']!),
      ),
      // My Tickets Page  
      GoRoute(
        path: '/book/:eventId',
        builder: (_, state) =>
            BookingPage(eventId: state.pathParameters['eventId']!),
      ),
      
      GoRoute(
        path: '/ticket/:id',
        builder: (_, state) =>
            TicketDetailPage(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create-event',
        builder: (_, __) => const CreateEventPage(),
      ),
      // Edit Event Page with event data passed as extra
      GoRoute(
        path: '/edit-event',
        builder: (_, state) {
          final event = state.extra as EventEntity;
          return CreateEventPage.edit(existingEvent: event);
        },
      ),
      GoRoute(
        path: '/organizer/event-view',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OrganizerEventViewPage(
            event: extra['event'] as EventEntity,
            organizerId: extra['organizerId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/organizer/event-update',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return UpdateEventPage(
            event: extra['event'] as EventEntity,
            organizerId: extra['organizerId'] as String,
          );
        },
      ),
      GoRoute(path: '/scan', builder: (_, __) => const QrScannerPage()),
      GoRoute(
        path: '/scan-result',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return QrResultPage(
            ticket: extra['ticket'],
            isValid: extra['isValid'] as bool,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
    ],
  );
}

// Helper to convert BLoC stream into Listenable for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
