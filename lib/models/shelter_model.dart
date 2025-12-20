import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool isGovernmentDesignated;

  const Shelter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.currentOccupancy,
    required this.status,
    this.isGovernmentDesignated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': GeoPoint(latitude, longitude),
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'status': status.name,
      'isGovernmentDesignated': isGovernmentDesignated,
    };
  }

  factory Shelter.fromMap(Map<String, dynamic> map, String id) {
    final location = map['location'] as GeoPoint? ?? const GeoPoint(0, 0);
    return Shelter(
      id: id,
      name: map['name'] ?? 'Unknown Shelter',
      latitude: location.latitude,
      longitude: location.longitude,
      capacity: map['capacity'] ?? 0,
      currentOccupancy: map['currentOccupancy'] ?? 0,
      status: ShelterStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => ShelterStatus.closed,
      ),
      isGovernmentDesignated: map['isGovernmentDesignated'] ?? false,
    );
  }
}

