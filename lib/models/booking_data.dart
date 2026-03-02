// lib/models/booking_data.dart

import 'route_model.dart';

/// Holds all booking selections passed between screens
class BookingData {
  final RouteModel route;
  final MoodOption? mood;
  final String goal;
  final DurationOption duration;
  final DateTime createdAt;

  BookingData({
    required this.route,
    this.mood,
    required this.goal,
    required this.duration,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get gateNumber {
    return '${(createdAt.minute % 9) + 1}${String.fromCharCode(65 + createdAt.second % 5)}';
  }

  String get seatNumber {
    return '${(createdAt.day % 20) + 1}${String.fromCharCode(65 + createdAt.hour % 6)}';
  }

  String get departureTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get arrivalTime {
    final arrival = createdAt.add(Duration(minutes: duration.minutes));
    return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
  }
}