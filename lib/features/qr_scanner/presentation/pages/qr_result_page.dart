import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../tickets/domain/entities/ticket_entity.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/bloc/event_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class QrResultPage extends StatelessWidget {
  final TicketEntity ticket;
  final bool isValid;

  const QrResultPage({required this.ticket, required this.isValid, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Result'),
        backgroundColor: const Color(0xFF1F5FA6),
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              _buildStatusCard(isValid),
              const SizedBox(height: 24),

              // Event Details
              _buildSectionTitle('Event Details'),
              _buildEventDetails(context),
              const SizedBox(height: 24),

              // Attendee Information
              _buildSectionTitle('Attendee'),
              _buildAttendeeInfo(context),
              const SizedBox(height: 24),

              // Ticket Information
              _buildSectionTitle('Ticket Information'),
              _buildTicketInfo(context),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isValid) {
    final backgroundColor = isValid ? Colors.green[50] : Colors.red[50];
    final borderColor = isValid ? Colors.green : Colors.red;
    final statusText = isValid ? 'Valid Ticket' : 'Invalid/Used Ticket';
    final statusIcon = isValid ? Icons.check_circle : Icons.cancel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: borderColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F5FA6),
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        if (state is EventsLoaded) {
          EventEntity? event;
          try {
            event = state.events.firstWhere((e) => e.id == ticket.eventId);
          } catch (_) {
            event = null;
          }

          if (event != null) {
            return _buildEventCard(event);
          }
        }

        // If event not in current state, we'll show ticket event ID
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Event ID: ${ticket.eventId}'),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(EventEntity event) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null)
            Image.network(
              event.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(event.eventDate),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeInfo(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String attendeeName = 'Attendee';
        String attendeeEmail = 'N/A';
        String attendeeContactNumber = 'N/A';
        if (state is AuthAuthenticated) {
          attendeeName = state.user.name;
          attendeeEmail = state.user.email;
          attendeeContactNumber =
              state.user.contactNumber?.toString().isNotEmpty == true
              ? state.user.contactNumber.toString()
              : 'N/A';
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5FA6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Name',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            attendeeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      attendeeEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contact Number',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      attendeeContactNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketInfo(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userEmail = 'N/A';
        String userContactNumber = 'N/A';
        if (authState is AuthAuthenticated) {
          userEmail = authState.user.email;
          userContactNumber =
              authState.user.contactNumber?.toString().isNotEmpty == true
              ? authState.user.contactNumber.toString()
              : 'N/A';
        }

        // Build seat display from seat_number and raw_label
        final seatDisplay = ticket.rawLabel != null && ticket.seatNumber != null
            ? '${ticket.rawLabel}${ticket.seatNumber}'
            : 'N/A';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Ticket ID', ticket.id.substring(0, 16)),
                const SizedBox(height: 12),
                _buildInfoRow('Seat', seatDisplay),
                const SizedBox(height: 12),
                _buildInfoRow('Email', userEmail),
                const SizedBox(height: 12),
                _buildInfoRow('Contact Number', userContactNumber),
                const SizedBox(height: 12),
                _buildInfoRow('Status', ticket.status.toUpperCase()),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Booked At',
                  _formatDate(DateTime.parse(ticket.bookedAt)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F5FA6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
