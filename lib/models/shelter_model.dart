import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ShelterStatus { available, full, closed }

@immutable
class Shelter {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final int capacity;
  final int currentOccupancy;
  final ShelterStatus status;
  final bool isGovernmentDesignated;
  
  // New fields from Firebase
  final List<String> amenities;
  final String contactPerson;
  final String contactPhone;
  final String district;
  final String location; // Address string
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Shelter({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    required this.capacity,
    required this.currentOccupancy,
    required this.status,
    this.isGovernmentDesignated = false,
    this.amenities = const [],
    this.contactPerson = '',
    this.contactPhone = '',
    this.district = '',
    this.location = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Check if shelter has valid coordinates for map display
  bool get hasValidCoordinates => 
      latitude != null && longitude != null && 
      latitude != 0 && longitude != 0;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'coordinates': hasValidCoordinates 
          ? GeoPoint(latitude!, longitude!) 
          : null,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'status': status.name,
      'isGovernmentDesignated': isGovernmentDesignated,
      'amenities': amenities,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'district': district,
      'location': location,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Shelter.fromMap(Map<String, dynamic> map, String id) {
    // Parse coordinates - could be GeoPoint or null
    double? lat;
    double? lng;
    
    final coordinates = map['coordinates'];
    if (coordinates != null && coordinates is GeoPoint) {
      lat = coordinates.latitude;
      lng = coordinates.longitude;
    }
    
    // Parse amenities - could be List<dynamic> or null
    List<String> amenitiesList = [];
    if (map['amenities'] != null && map['amenities'] is List) {
      amenitiesList = (map['amenities'] as List)
          .map((e) => e.toString())
          .toList();
    }
    
    // Parse timestamps
    DateTime? createdAt;
    DateTime? updatedAt;
    
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    }
    if (map['updatedAt'] != null && map['updatedAt'] is Timestamp) {
      updatedAt = (map['updatedAt'] as Timestamp).toDate();
    }
    
    return Shelter(
      id: id,
      name: map['name'] ?? 'Unknown Shelter',
      latitude: lat,
      longitude: lng,
      capacity: map['capacity'] ?? 0,
      currentOccupancy: map['currentOccupancy'] ?? 0,
      status: ShelterStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => ShelterStatus.closed,
      ),
      isGovernmentDesignated: map['isGovernmentDesignated'] ?? false,
      amenities: amenitiesList,
      contactPerson: map['contactPerson'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      district: map['district'] ?? '',
      location: map['location'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
