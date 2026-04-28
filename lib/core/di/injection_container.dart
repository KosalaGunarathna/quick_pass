import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/events/data/datasources/event_datasource.dart';
import '../../features/events/data/datasources/event_local_datasource.dart';
import '../../features/events/data/repositories/event_repository_impl.dart';
import '../../features/events/domain/repositories/event_repository.dart';
import '../../features/events/domain/usecases/event_usecases.dart';
import '../../features/events/presentation/bloc/event_bloc.dart';
import '../../features/tickets/data/datasources/ticket_local_datasource.dart';
import '../../features/tickets/data/repositories/ticket_repository_impl.dart';
import '../../features/tickets/domain/repositories/ticket_repository.dart';
import '../../features/tickets/presentation/bloc/ticket_bloc.dart';

import '../../shared/local_db/database_helper.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // ── Auth ──────────────────────────────────────────
  sl.registerLazySingleton<AuthLocalDatasource>(
    () => AuthLocalDatasource(db: sl(), prefs: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDatasource: sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      updateProfileUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // ── Events ────────────────────────────────────────
  sl.registerLazySingleton<EventLocalDatasource>(
    () => EventLocalDatasourceImpl(db: sl()),
  );

  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(local: sl()),
  );

  sl.registerLazySingleton(() => GetEventsUseCase(sl()));
  sl.registerLazySingleton(() => GetEventsByOrganizerUseCase(sl()));
  sl.registerLazySingleton(() => GetEventByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateEventUseCase(sl()));
  sl.registerLazySingleton(() => GetSeatsUseCase(sl()));

  sl.registerFactory(
    () => EventBloc(
      getEvents: sl(),
      getEventsByOrganizer: sl(),
      getEventById: sl(),
      createEvent: sl(),
      getSeats: sl(),
      eventRepository: sl(),
    ),
  );

  // ── Tickets ───────────────────────────────────────
  sl.registerLazySingleton<TicketLocalDatasource>(
    () => TicketLocalDatasource(db: sl()),
  );
  sl.registerLazySingleton<TicketRepository>(
    () => TicketRepositoryImpl(local: sl()),
  );

  sl.registerLazySingleton(() => BookTicketUseCase(sl()));
  sl.registerLazySingleton(() => GetMyTicketsUseCase(sl()));
  sl.registerLazySingleton(() => GetEventBookingsUseCase(sl()));
  sl.registerLazySingleton(() => ValidateTicketUseCase(sl()));
  sl.registerLazySingleton(() => MarkTicketUsedUseCase(sl()));

  sl.registerFactory(
    () => TicketBloc(
      bookTicket: sl(),
      getMyTickets: sl(),
      getEventBookings: sl(),
      validateTicket: sl(),
      markTicketUsed: sl(),
    ),
  );
}
