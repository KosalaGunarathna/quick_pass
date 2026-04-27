import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/event_booking_entity.dart';
import '../../domain/repositories/ticket_repository.dart';

// Events
abstract class TicketEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TicketBook extends TicketEvent {
  final String eventId, userId, seatId;
  TicketBook({
    required this.eventId,
    required this.userId,
    required this.seatId,
  });
  @override
  List<Object?> get props => [eventId, seatId];
}

class TicketLoadMine extends TicketEvent {
  final String userId;
  TicketLoadMine(this.userId);
  @override
  List<Object?> get props => [userId];
}

class TicketLoadByEvent extends TicketEvent {
  final String eventId;
  TicketLoadByEvent(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

class TicketValidate extends TicketEvent {
  final String qrData;
  TicketValidate(this.qrData);
  @override
  List<Object?> get props => [qrData];
}

class TicketMarkUsed extends TicketEvent {
  final String ticketId;
  TicketMarkUsed(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

// States
abstract class TicketState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketsLoaded extends TicketState {
  final List<TicketEntity> tickets;
  TicketsLoaded(this.tickets);
  @override
  List<Object?> get props => [tickets];
}

class EventBookingsLoaded extends TicketState {
  final List<EventBookingEntity> bookings;
  EventBookingsLoaded(this.bookings);
  @override
  List<Object?> get props => [bookings];
}

class TicketBooked extends TicketState {
  final TicketEntity ticket;
  TicketBooked(this.ticket);
  @override
  List<Object?> get props => [ticket.id];
}

class TicketValidated extends TicketState {
  final TicketEntity? ticket;
  final bool isValid;
  TicketValidated({this.ticket, required this.isValid});
  @override
  List<Object?> get props => [ticket?.id, isValid];
}

class TicketMarkedUsed extends TicketState {}

class TicketError extends TicketState {
  final String message;
  TicketError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final BookTicketUseCase bookTicket;
  final GetMyTicketsUseCase getMyTickets;
  final GetEventBookingsUseCase getEventBookings;
  final ValidateTicketUseCase validateTicket;
  final MarkTicketUsedUseCase markTicketUsed;

  TicketBloc({
    required this.bookTicket,
    required this.getMyTickets,
    required this.getEventBookings,
    required this.validateTicket,
    required this.markTicketUsed,
  }) : super(TicketInitial()) {
    on<TicketBook>(_onBook);
    on<TicketLoadMine>(_onLoadMine);
    on<TicketLoadByEvent>(_onLoadByEvent);
    on<TicketValidate>(_onValidate);
    on<TicketMarkUsed>(_onMarkUsed);
  }

  Future<void> _onBook(TicketBook e, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final ticket = await bookTicket(
        eventId: e.eventId,
        userId: e.userId,
        seatId: e.seatId,
      );
      emit(TicketBooked(ticket));
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onLoadMine(TicketLoadMine e, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final tickets = await getMyTickets(e.userId);
      emit(TicketsLoaded(tickets));
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onLoadByEvent(
    TicketLoadByEvent e,
    Emitter<TicketState> emit,
  ) async {
    emit(TicketLoading());
    try {
      final bookings = await getEventBookings(e.eventId);
      emit(EventBookingsLoaded(bookings));
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onValidate(TicketValidate e, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final ticket = await validateTicket(e.qrData);
      emit(
        TicketValidated(
          ticket: ticket,
          isValid: ticket != null && ticket.isActive,
        ),
      );
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onMarkUsed(TicketMarkUsed e, Emitter<TicketState> emit) async {
    try {
      await markTicketUsed(e.ticketId);
      emit(TicketMarkedUsed());
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }
}
