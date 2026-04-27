import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ticket_entity.dart';
import '../bloc/ticket_bloc.dart';

// My Tickets Page
class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});
  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _userId = auth.user.id;
      context.read<TicketBloc>().add(TicketLoadMine(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        backgroundColor: Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TicketBooked || state is TicketMarkedUsed) {
            final auth = context.read<AuthBloc>().state;
            if (auth is AuthAuthenticated) {
              context.read<TicketBloc>().add(TicketLoadMine(auth.user.id));
            }
          }
        },
        builder: (context, state) {
          if (state is TicketLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TicketsLoaded) {
            if (state.tickets.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tickets yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.tickets.length,
              itemBuilder: (_, i) =>
                  TicketCard(ticket: state.tickets[i], userId: _userId),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final TicketEntity ticket;
  final String? userId;
  const TicketCard({super.key, required this.ticket, this.userId});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(ticket.bookedAt);
    final formatted = date != null
        ? DateFormat('MMM dd, yyyy').format(date)
        : ticket.bookedAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await context.push('/ticket/${ticket.id}');
          if (!context.mounted || userId == null) return;
          context.read<TicketBloc>().add(TicketLoadMine(userId!));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ticket.isActive
                      ? Color(0xFF673AB7)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.confirmation_number,
                  color: ticket.isActive ? Color(0xFF673AB7) : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket #${ticket.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booked: $formatted',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ticket.isActive
                      ? Colors.green.shade50
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ticket.isActive
                        ? Colors.green.shade700
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ticket Detail Page (shows QR)
class TicketDetailPage extends StatefulWidget {
  final String ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final GlobalKey _qrBoundaryKey = GlobalKey();

  Future<void> _downloadQr(TicketEntity ticket) async {
    try {
      final boundary =
          _qrBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to capture QR image')),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to export QR image')),
        );
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final filePath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}ticket_${ticket.id}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR saved: $filePath')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save QR')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ticket'),
        backgroundColor: Color(0xFF673AB7),
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          TicketEntity? ticket;
          if (state is TicketBooked) ticket = state.ticket;
          if (state is TicketsLoaded) {
            final match = state.tickets
                .where((t) => t.id == widget.ticketId)
                .toList();
            if (match.isNotEmpty) ticket = match.first;
          }

          if (ticket == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ticket #${ticket.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ticket.isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ticket.status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ticket.isActive
                                ? Colors.green.shade700
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // QR Code
                      RepaintBoundary(
                        key: _qrBoundaryKey,
                        child: QrImageView(
                          data: ticket.qrData,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF673AB7),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadQr(ticket!),
                          icon: const Icon(Icons.download),
                          label: const Text('Download QR'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      _row('Ticket ID', ticket.id.substring(0, 16)),
                      _row('Seat', ticket.seatId.split('_').last),
                      _row('Status', ticket.status),
                      _row(
                        'Booked',
                        DateFormat(
                          'MMM dd, yyyy HH:mm',
                        ).format(DateTime.parse(ticket.bookedAt)),
                      ),
                    ],
                  ),
                ),
                if (ticket.isActive) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Show this QR code at the entrance',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
