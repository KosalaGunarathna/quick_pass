import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime eventDate;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final int totalSeats;
  final int availableSeats;
  final String organizerId;
  final double ticketPrice;
  final bool isFeatured;
  final DateTime createdAt;

  const EventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eventDate,
    required this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.totalSeats,
    required this.availableSeats,
    required this.organizerId,
    required this.ticketPrice,
    this.isFeatured = false,
    required this.createdAt,
  });

  // Compatibility getters used in existing UI code.
  String get date => eventDate.toIso8601String();
  String get venue => location;
  double get price => ticketPrice;
  bool get hasAvailableSeats => availableSeats > 0;
  bool get hasLocationCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    eventDate,
    location,
    latitude,
    longitude,
    imageUrl,
    totalSeats,
    availableSeats,
    organizerId,
    ticketPrice,
    isFeatured,
    createdAt,
  ];
}
