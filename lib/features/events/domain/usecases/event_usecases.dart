import '../entities/event_entity.dart';
import '../entities/seat_entity.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase {
  final EventRepository repository;

  GetEventsUseCase(this.repository);

  Future<List<EventEntity>> call() {
    return repository.getEvents();
  }
}

class GetEventsByOrganizerUseCase {
  final EventRepository repository;

  GetEventsByOrganizerUseCase(this.repository);

  Future<List<EventEntity>> call(String organizerId) {
    return repository.getEventsByOrganizer(organizerId);
  }
}

class GetEventByIdUseCase {
  final EventRepository repository;

  GetEventByIdUseCase(this.repository);

  Future<EventEntity> call(String id) {
    return repository.getEventById(id);
  }
}

class CreateEventUseCase {
  final EventRepository repository;

  CreateEventUseCase(this.repository);

  Future<void> call(EventEntity event) {
    return repository.createEvent(event);
  }
}

class GetSeatsUseCase {
  final EventRepository repository;

  GetSeatsUseCase(this.repository);

  Future<List<SeatEntity>> call(String eventId) {
    return repository.getSeatsByEvent(eventId);
  }
}
