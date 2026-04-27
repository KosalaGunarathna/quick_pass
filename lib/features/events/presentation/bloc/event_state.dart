import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_event/features/events/domain/repositories/event_repository.dart';
import '../../../notifications/data/datasources/notification_service.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/seat_entity.dart';
import '../../domain/usecases/event_usecases.dart';

// Events
abstract class EventEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventLoadAll extends EventEvent {}

class EventLoadByOrganizer extends EventEvent {
  final String organizerId;
  EventLoadByOrganizer(this.organizerId);
  @override
  List<Object?> get props => [organizerId];
}

class EventLoadById extends EventEvent {
  final String eventId;
  EventLoadById(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

class EventCreate extends EventEvent {
  final EventEntity event;
  final int rows;
  final int seatsPerRow;
  EventCreate(this.event, {this.rows = 5, this.seatsPerRow = 10});
  @override
  List<Object?> get props => [event.id];
}

class EventUpdate extends EventEvent {
  final EventEntity event;
  EventUpdate(this.event);
  @override
  List<Object?> get props => [event.id];
}

class EventDelete extends EventEvent {
  final String eventId;
  EventDelete(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

class SeatsLoad extends EventEvent {
  final String eventId;
  SeatsLoad(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

// States
abstract class EventState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventsLoaded extends EventState {
  final List<EventEntity> events;
  EventsLoaded(this.events);
  @override
  List<Object?> get props => [events];
}

class EventDetailLoaded extends EventState {
  final EventEntity event;
  EventDetailLoaded(this.event);
  @override
  List<Object?> get props => [event.id];
}

class SeatsLoaded extends EventState {
  final List<SeatEntity> seats;
  SeatsLoaded(this.seats);
  @override
  List<Object?> get props => [seats];
}

class EventCreated extends EventState {}

class EventUpdated extends EventState {}

class EventDeleted extends EventState {}

class EventError extends EventState {
  final String message;
  EventError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class EventBloc extends Bloc<EventEvent, EventState> {
  final GetEventsUseCase getEvents;
  final GetEventsByOrganizerUseCase getEventsByOrganizer;
  final GetEventByIdUseCase getEventById;
  final CreateEventUseCase createEvent;
  final GetSeatsUseCase getSeats;
  final EventRepository eventRepository;

  EventBloc({
    required this.getEvents,
    required this.getEventsByOrganizer,
    required this.getEventById,
    required this.createEvent,
    required this.getSeats,
    required this.eventRepository,
  }) : super(EventInitial()) {
    on<EventLoadAll>(_onLoadAll);
    on<EventLoadByOrganizer>(_onLoadByOrganizer);
    on<EventLoadById>(_onLoadById);
    on<EventCreate>(_onCreate);
    on<EventUpdate>(_onUpdate);
    on<EventDelete>(_onDelete);
    on<SeatsLoad>(_onSeatsLoad);
  }

  Future<void> _onLoadAll(EventLoadAll e, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final events = await getEvents();
      emit(EventsLoaded(events));
    } catch (ex) {
      emit(EventError(ex.toString()));
    }
  }

  Future<void> _onLoadByOrganizer(
    EventLoadByOrganizer e,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      final events = await getEventsByOrganizer(e.organizerId);
      emit(EventsLoaded(events));
    } catch (ex) {
      emit(EventError(ex.toString()));
    }
  }

  Future<void> _onLoadById(EventLoadById e, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final event = await getEventById(e.eventId);
      emit(EventDetailLoaded(event));
    } catch (ex) {
      emit(EventError(ex.toString()));
    }
  }

  Future<void> _onCreate(EventCreate e, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      await createEvent(e.event);
      final seats = _generateSeatsForTotal(
        eventId: e.event.id,
        totalSeats: e.event.totalSeats,
      );
      await eventRepository.createSeats(seats);
      try {
        await NotificationService.instance.cancelAllNotifications();
      } catch (_) {
        // Keep event creation successful even if notification plugin fails.
      }
      emit(EventCreated());
    } catch (ex) {
      emit(EventError(ex.toString()));
    }
  }

  String _rowLabelFromIndex(int index) {
    var n = index;
    var label = '';
    while (n >= 0) {
      label = String.fromCharCode((n % 26) + 65) + label;
      n = (n ~/ 26) - 1;
    }
    return label;
  }

  Future<void> _onUpdate(EventUpdate e, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final existingSeats = await eventRepository.getSeatsByEvent(e.event.id);
      final bookedSeats = existingSeats.where((s) => !s.isAvailable).toList();

      if (e.event.totalSeats < bookedSeats.length) {
        emit(
          EventError(
            'Cannot reduce seats below booked seats (${bookedSeats.length}).',
          ),
        );
        return;
      }

      final desiredSeats = _generateSeatsForTotal(
        eventId: e.event.id,
        totalSeats: e.event.totalSeats,
      );
      final desiredIds = desiredSeats.map((s) => s.id).toSet();
      final existingById = {for (final seat in existingSeats) seat.id: seat};

      final toCreate = desiredSeats
          .where((seat) => !existingById.containsKey(seat.id))
          .toList();
      final toDeleteIds = existingSeats
          .where((seat) => !desiredIds.contains(seat.id) && seat.isAvailable)
          .map((seat) => seat.id)
          .toList();

      if (toCreate.isNotEmpty) {
        await eventRepository.createSeats(toCreate);
      }
      if (toDeleteIds.isNotEmpty) {
        await eventRepository.deleteSeatsByIds(e.event.id, toDeleteIds);
      }

      final availableSeats = e.event.totalSeats - bookedSeats.length;
      final syncedEvent = EventEntity(
        id: e.event.id,
        title: e.event.title,
        description: e.event.description,
        category: e.event.category,
        eventDate: e.event.eventDate,
        location: e.event.location,
        imageUrl: e.event.imageUrl,
        totalSeats: e.event.totalSeats,
        availableSeats: availableSeats < 0 ? 0 : availableSeats,
        organizerId: e.event.organizerId,
        ticketPrice: e.event.ticketPrice,
        isFeatured: e.event.isFeatured,
        createdAt: e.event.createdAt,
      );

      await eventRepository.updateEvent(syncedEvent);
      emit(EventUpdated());
    } catch (ex) {
      emit(EventError(ex.toString()));
    }
  }

  Future<void> _onDelete(EventDelete e, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      await eventRepository.deleteEvent(e.eventId);
      emit(EventDeleted());
    } catch (ex) {
      emit(EventError(ex.toString()));
    }
  }

  Future<void> _onSeatsLoad(SeatsLoad e, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final seats = await getSeats(e.eventId);
      emit(SeatsLoaded(seats));
    } catch (ex) {
      emit(EventError(ex.toString()));
    }
  }

  List<SeatEntity> _generateSeatsForTotal({
    required String eventId,
    required int totalSeats,
    int seatsPerRow = 10,
  }) {
    final normalizedSeatsPerRow = seatsPerRow <= 0 ? 10 : seatsPerRow;
    final seats = <SeatEntity>[];

    for (var seatOffset = 0; seatOffset < totalSeats; seatOffset++) {
      final rowIndex = seatOffset ~/ normalizedSeatsPerRow;
      final seatNumber = (seatOffset % normalizedSeatsPerRow) + 1;
      final rowLabel = _rowLabelFromIndex(rowIndex);

      seats.add(
        SeatEntity(
          id: '${eventId}_${rowLabel}$seatNumber',
          eventId: eventId,
          seatNumber: seatNumber,
          rowLabel: rowLabel,
          status: 'available',
          isAvailable: true,
        ),
      );
    }

    return seats;
  }
}
