import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum IncidentType { flood, fire, accident, medical, earthquake, other }

enum Severity { low, medium, high, critical }

@immutable
class Incident {
  final String? id; // Can be null when creating a new incident
  final IncidentType type;
  final String description;
  final Severity severity;
  final double latitude;
  final double longitude;
  final String reportedBy; // User ID
  final DateTime timestamp;

  const Incident({
    this.id,
    required this.type,
    required this.description,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.reportedBy,
    required this.timestamp,
  });

  // Converts an Incident object into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'description': description,
      'severity': severity.name,
      'location': GeoPoint(latitude, longitude), // Use Firestore's GeoPoint
      'reportedBy': reportedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

