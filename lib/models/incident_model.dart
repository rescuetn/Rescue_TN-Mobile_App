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
  final String? district;
  final String reportedBy;
  final DateTime timestamp;
  final List<String> imageUrls;
  final List<String> audioUrls;
  final bool isVerified;

  const Incident({
    this.id,
    required this.type,
    required this.description,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.district,
    required this.reportedBy,
    required this.timestamp,
    this.imageUrls = const [],
    this.audioUrls = const [],
    this.isVerified = false,
  });

  Incident copyWith({
    String? district,
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
      district: district ?? this.district,
      reportedBy: reportedBy,
      timestamp: timestamp,
      imageUrls: imageUrls ?? this.imageUrls,
      audioUrls: audioUrls ?? this.audioUrls,
      isVerified: isVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'description': description,
      'severity': severity.name,
      'location': GeoPoint(latitude, longitude),
      'district': district,
      'reportedBy': reportedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrls': imageUrls,
      'audioUrls': audioUrls,
      'isVerified': isVerified,
    };
  }

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
      district: map['district'],
      reportedBy: map['reportedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      audioUrls: List<String>.from(map['audioUrls'] ?? []),
      isVerified: map['isVerified'] ?? false,
    );
  }
}

