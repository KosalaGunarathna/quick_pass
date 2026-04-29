import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/events/presentation/bloc/event_bloc.dart';
import 'features/tickets/presentation/bloc/ticket_bloc.dart';
import 'features/notifications/data/datasources/event_reminder_service.dart';
import 'features/notifications/domain/usecases/schedule_event_reminders_use_case.dart';

class SmartEventApp extends StatefulWidget {
  const SmartEventApp({super.key});
  @override
  State<SmartEventApp> createState() => _SmartEventAppState();
}

class _SmartEventAppState extends State<SmartEventApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  late final ScheduleEventRemindersUseCase _scheduleRemindersUseCase;
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(AuthCheckRequested());
    _router = buildRouter(_authBloc);
    _scheduleRemindersUseCase = ScheduleEventRemindersUseCase(
      EventReminderService.instance,
    );

    // Start periodic reminder scheduling (every 10 minutes)
    _startReminderScheduler();
  }

  /// Start periodic reminder scheduling
  void _startReminderScheduler() {
    _reminderTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _scheduleRemindersUseCase.call(),
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    _reminderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(create: (_) => sl<EventBloc>()),
        BlocProvider(create: (_) => sl<TicketBloc>()),
      ],
      child: MaterialApp.router(
        title: 'EventHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
