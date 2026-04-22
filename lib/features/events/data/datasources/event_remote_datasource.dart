import '../../domain/entities/event_entity.dart';
import 'event_datasource.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventRemoteDatasourceImpl implements EventRemoteDatasource {
  static const String _apiBase =
      'https://app.ticketmaster.com/discovery/v2/events.json';
  static const String _apiKey = String.fromEnvironment('TM_API_KEY');

  @override
  Future<List<EventEntity>> getEvents() async {
    try {
      if (_apiKey.isEmpty) return [];

      final uri = Uri.parse('$_apiBase?apikey=$_apiKey&size=10&sort=date,asc');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Remote API status: ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final embedded = body['_embedded'] as Map<String, dynamic>?;
      final events = (embedded?['events'] as List<dynamic>?) ?? [];

      return events.map((e) {
        final map = e as Map<String, dynamic>;
        final dates = map['dates'] as Map<String, dynamic>?;
        final start = dates?['start'] as Map<String, dynamic>?;
        final classifications = map['classifications'] as List<dynamic>?;
        final firstClass = classifications != null && classifications.isNotEmpty
            ? classifications.first as Map<String, dynamic>
            : null;
        final segment = firstClass?['segment'] as Map<String, dynamic>?;
        final images = map['images'] as List<dynamic>?;
        final venueEmbedded = map['_embedded'] as Map<String, dynamic>?;
        final venues = venueEmbedded?['venues'] as List<dynamic>?;
        final firstVenue = venues != null && venues.isNotEmpty
            ? venues.first as Map<String, dynamic>
            : null;

        return EventEntity(
          id: (map['id'] ?? '').toString(),
          title: (map['name'] ?? 'Featured Event').toString(),
          description: (map['info'] ?? map['pleaseNote'] ?? 'Featured event')
              .toString(),
          category: (segment?['name'] ?? 'general').toString(),
          eventDate:
              DateTime.tryParse((start?['dateTime'] ?? '').toString()) ??
              DateTime.now().add(const Duration(days: 7)),
          location: (firstVenue?['name'] ?? 'Unknown venue').toString(),
          imageUrl: images != null && images.isNotEmpty
              ? (images.first as Map<String, dynamic>)['url']?.toString()
              : null,
          totalSeats: 100,
          availableSeats: 100,
          organizerId: 'remote',
          ticketPrice: 0,
          isFeatured: true,
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching events from remote: $e');
    }
  }

  @override
  Future<EventEntity> getEventById(String id) async {
    try {
      final events = await getEvents();
      return events.firstWhere((event) => event.id == id);
    } catch (e) {
      throw Exception('Error fetching event from remote: $e');
    }
  }
}
