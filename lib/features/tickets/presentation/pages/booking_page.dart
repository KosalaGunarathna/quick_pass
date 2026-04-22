import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../events/domain/entities/seat_entity.dart';
import '../../../events/presentation/bloc/event_bloc.dart';
import '../bloc/ticket_bloc.dart';

class BookingPage extends StatefulWidget {
  final String eventId;
  const BookingPage({super.key, required this.eventId});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String? _selectedSeatId;
  String? _selectedSeatLabel;

  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(SeatsLoad(widget.eventId));
  }

  void _confirmBooking() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    if (_selectedSeatId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a seat')));
      return;
    }
    context.read<TicketBloc>().add(
      TicketBook(
        eventId: widget.eventId,
        userId: authState.user.id,
        seatId: _selectedSeatId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Seat'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TicketBooked) {
            context.pushReplacement('/ticket/${state.ticket.id}');
          } else if (state is TicketError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, ticketState) {
          return Column(
            children: [
              // Stage indicator
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'STAGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(Colors.green.shade100, 'Available'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.deepPurple, 'Selected'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.grey.shade300, 'Booked'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Seat grid
              Expanded(
                child: BlocBuilder<EventBloc, EventState>(
                  builder: (context, state) {
                    if (state is EventLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is SeatsLoaded) {
                      final grouped = <String, List<SeatEntity>>{};
                      for (final s in state.seats) {
                        grouped.putIfAbsent(s.rowLabel, () => []).add(s);
                      }
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: grouped.entries.map((entry) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: entry.value.map((seat) {
                                    final isSelected =
                                        _selectedSeatId == seat.id;
                                    final isBooked = !seat.isAvailable;
                                    return GestureDetector(
                                      onTap: isBooked
                                          ? null
                                          : () => setState(() {
                                              _selectedSeatId = seat.id;
                                              _selectedSeatLabel =
                                                  '${seat.rowLabel}${seat.seatNumber}';
                                            }),
                                      child: Container(
                                        width: 36,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isBooked
                                              ? Colors.grey.shade300
                                              : isSelected
                                              ? Colors.deepPurple
                                              : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.deepPurple
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${seat.seatNumber}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isBooked
                                                  ? Colors.grey
                                                  : isSelected
                                                  ? Colors.white
                                                  : Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }
                    return const Center(child: Text('No seats available'));
                  },
                ),
              ),
              // Bottom bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedSeatLabel != null
                            ? 'Seat: $_selectedSeatLabel selected'
                            : 'No seat selected',
                        style: TextStyle(
                          color: _selectedSeatLabel != null
                              ? Colors.deepPurple
                              : Colors.grey,
                        ),
                      ),
                    ),
                    if (ticketState is TicketLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _selectedSeatId != null
                            ? _confirmBooking
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Confirm Booking'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
