import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_bloc.dart';
import '../pages/location_picker_page.dart';

class CreateEventPage extends StatefulWidget {
  final EventEntity? existingEvent;
  const CreateEventPage({super.key, this.existingEvent});

  const CreateEventPage.edit({
    super.key,
    required EventEntity this.existingEvent,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');
  final _seatsCtrl = TextEditingController(text: '50');
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  double? _latitude;
  double? _longitude;

  bool get _isEditMode => widget.existingEvent != null;
  bool get _hasLocationSelected => _latitude != null && _longitude != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descCtrl.text = existing.description;
      _venueCtrl.text = existing.location;
      _priceCtrl.text = existing.ticketPrice.toString();
      _seatsCtrl.text = existing.totalSeats.toString();
      _selectedDate = existing.eventDate;
      _latitude = existing.latitude;
      _longitude = existing.longitude;
     
    }
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(
          () => _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          ),
        );
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialLocationName: _venueCtrl.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _venueCtrl.text = result['locationName'];
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final seats = int.tryParse(_seatsCtrl.text) ?? 50;
    final existing = widget.existingEvent;
    final event = EventEntity(
      id: existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: existing?.category ?? 'general',
      eventDate: _selectedDate,
      location: _venueCtrl.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      organizerId: authState.user.id,
      totalSeats: seats,
      availableSeats: existing?.availableSeats ?? seats,
      ticketPrice: double.tryParse(_priceCtrl.text) ?? 0,
      isFeatured: existing?.isFeatured ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    if (_isEditMode) {
      context.read<EventBloc>().add(EventUpdate(event));
    } else {
      context.read<EventBloc>().add(EventCreate(event));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Event' : 'Create Event'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event created!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is EventUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Event updated!'),
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map),
                    label: Text(
                      _hasLocationSelected
                          ? 'Change Location'
                          : 'Select Location on Map',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: _hasLocationSelected
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ),
                  if (_hasLocationSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          'Location selected ✓ (${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)})',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
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
                      icon: Icon(_isEditMode ? Icons.save : Icons.add),
                      label: Text(
                        _isEditMode ? 'Update Event' : 'Create Event',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
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
