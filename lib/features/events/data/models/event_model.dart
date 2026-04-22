import 'package:smart_event/features/events/domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required String id,
    required String title,
    required String description,
    required String category,
    required DateTime eventDate,
    required String location,
    String? imageUrl,
    required int totalSeats,
    required int availableSeats,
    required String organizerId,
    required double ticketPrice,
    bool isFeatured = false,
    required DateTime createdAt,
  }) : super(
         id: id,
         title: title,
         description: description,
         category: category,
         eventDate: eventDate,
         location: location,
         imageUrl: imageUrl,
         totalSeats: totalSeats,
         availableSeats: availableSeats,
         organizerId: organizerId,
         ticketPrice: ticketPrice,
         isFeatured: isFeatured,
         createdAt: createdAt,
       );

  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      eventDate: entity.eventDate,
      location: entity.location,
      imageUrl: entity.imageUrl,
      totalSeats: entity.totalSeats,
      availableSeats: entity.availableSeats,
      organizerId: entity.organizerId,
      ticketPrice: entity.ticketPrice,
      isFeatured: entity.isFeatured,
      createdAt: entity.createdAt,
    );
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      eventDate: map['event_date'] != null
          ? DateTime.parse(map['event_date'])
          : DateTime.now(),
      location: map['location'] ?? '',
      imageUrl: map['image_url'],
      totalSeats: map['total_seats'] ?? 0,
      availableSeats: map['available_seats'] ?? 0,
      organizerId: map['organizer_id'] ?? '',
      ticketPrice: (map['ticket_price'] ?? 0).toDouble(),
      isFeatured: map['is_featured'] == true || map['is_featured'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'event_date': eventDate.toIso8601String(),
      'location': location,
      'image_url': imageUrl,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'organizer_id': organizerId,
      'ticket_price': ticketPrice,
      'is_featured': isFeatured ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
