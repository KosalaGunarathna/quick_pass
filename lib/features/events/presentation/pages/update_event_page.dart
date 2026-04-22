import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_bloc.dart';

class UpdateEventPage extends StatefulWidget {
  final EventEntity event;
  final String organizerId;

  const UpdateEventPage({
    super.key,
    required this.event,
    required this.organizerId,
  });

  @override
  State<UpdateEventPage> createState() => _UpdateEventPageState();
}

class _UpdateEventPageState extends State<UpdateEventPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _seatsCtrl;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.event.title);
    _descCtrl = TextEditingController(text: widget.event.description);
    _venueCtrl = TextEditingController(text: widget.event.location);
    _priceCtrl = TextEditingController(
      text: widget.event.ticketPrice.toString(),
    );
    _seatsCtrl = TextEditingController(
      text: widget.event.totalSeats.toString(),
    );
    _selectedDate = widget.event.eventDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _priceCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final seats = int.tryParse(_seatsCtrl.text) ?? widget.event.totalSeats;
    final updatedEvent = EventEntity(
      id: widget.event.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: widget.event.category,
      eventDate: _selectedDate,
      location: _venueCtrl.text.trim(),
      imageUrl: widget.event.imageUrl,
      totalSeats: seats,
      availableSeats: widget.event.availableSeats > seats
          ? seats
          : widget.event.availableSeats,
      organizerId: authState.user.id,
      ticketPrice: double.tryParse(_priceCtrl.text) ?? 0,
      isFeatured: widget.event.isFeatured,
      createdAt: widget.event.createdAt,
    );

    context.read<EventBloc>().add(EventUpdate(updatedEvent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Event'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is EventError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    _titleCtrl,
                    'Event Title',
                    Icons.title,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    _descCtrl,
                    'Description',
                    Icons.description,
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    _venueCtrl,
                    'Venue',
                    Icons.location_on,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _priceCtrl,
                          'Price (\$)',
                          Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              double.tryParse(v!) == null ? 'Invalid' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _seatsCtrl,
                          'Total Seats',
                          Icons.event_seat,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              int.tryParse(v!) == null ? 'Invalid' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Event Date & Time',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  '
                        '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (state is EventLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Update Event',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    ),
  );
}
