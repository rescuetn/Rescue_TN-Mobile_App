import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentType { flood, fire, earthquake, accident, medical, other }

enum Severity { low, medium, high, critical }

class Incident {
  final String? id;
  final IncidentType type;
  final String description;
  final Severity severity;
  final double latitude;
  final double longitude;
  final String reportedBy;
  final DateTime timestamp;
  final List<String> imageUrls;
  final List<String> audioUrls;

  const Incident({
    this.id,
    required this.type,
    required this.description,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.reportedBy,
    required this.timestamp,
    this.imageUrls = const [],
    this.audioUrls = const [],
  });

  /// Creates a copy of the current Incident but with updated fields.
  /// This is used by the repository to add the media URLs after uploading.
  Incident copyWith({
    List<String>? imageUrls,
    List<String>? audioUrls,
  }) {
    return Incident(
      id: id,
      type: type,
      description: description,
      severity: severity,
      latitude: latitude,
      longitude: longitude,
      reportedBy: reportedBy,
      timestamp: timestamp,
      imageUrls: imageUrls ?? this.imageUrls,
      audioUrls: audioUrls ?? this.audioUrls,
    );
  }

  /// Converts an Incident object into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'description': description,
      'severity': severity.name,
      'location': GeoPoint(latitude, longitude),
      'reportedBy': reportedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrls': imageUrls,
      'audioUrls': audioUrls,
    };
  }

  /// Creates an Incident object from a Firestore document map.
  factory Incident.fromMap(Map<String, dynamic> map, String id) {
    final location = map['location'] as GeoPoint? ?? const GeoPoint(0, 0);
    return Incident(
      id: id,
      type: IncidentType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => IncidentType.other,
      ),
      description: map['description'] ?? '',
      severity: Severity.values.firstWhere(
            (e) => e.name == map['severity'],
        orElse: () => Severity.low,
      ),
      latitude: location.latitude,
      longitude: location.longitude,
      reportedBy: map['reportedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      audioUrls: List<String>.from(map['audioUrls'] ?? []),
    );
  }
}

