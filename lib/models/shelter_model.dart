import 'package:flutter/foundation.dart';

enum ShelterStatus { available, full, closed }

@immutable
class Shelter {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int capacity;
  final int currentOccupancy;
  final ShelterStatus status;

  const Shelter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.currentOccupancy,
    required this.status,
  });
}

