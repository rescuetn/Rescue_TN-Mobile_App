import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Person safety status matching backend values
enum PersonSafetyStatus { safe, missing, found }

@immutable
class PersonStatus {
  final String? id;
  final String name;
  final int age;
  final PersonSafetyStatus status;
  final String lastKnownLocation;
  final String submittedBy;
  final DateTime timestamp;
  final DateTime? updatedAt;

  const PersonStatus({
    this.id,
    required this.name,
    required this.age,
    required this.status,
    required this.lastKnownLocation,
    required this.submittedBy,
    required this.timestamp,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'status': status.name,
      'lastKnownLocation': lastKnownLocation,
      'submittedBy': submittedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory PersonStatus.fromMap(Map<String, dynamic> map, String id) {
    // Parse status string from backend
    PersonSafetyStatus parseStatus(String? statusStr) {
      if (statusStr == null) return PersonSafetyStatus.missing;
      final normalized = statusStr.toLowerCase().trim();
      switch (normalized) {
        case 'safe':
          return PersonSafetyStatus.safe;
        case 'found':
          return PersonSafetyStatus.found;
        case 'missing':
        default:
          return PersonSafetyStatus.missing;
      }
    }

    // Parse timestamp safely
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    return PersonStatus(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] is int ? map['age'] : int.tryParse(map['age'].toString()) ?? 0,
      status: parseStatus(map['status']?.toString()),
      lastKnownLocation: map['lastKnownLocation'] ?? '',
      submittedBy: map['submittedBy'] ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      updatedAt: map['updatedAt'] != null ? parseTimestamp(map['updatedAt']) : null,
    );
  }

  /// Get display-friendly status text
  String get statusText {
    switch (status) {
      case PersonSafetyStatus.safe:
        return 'Marked Safe';
      case PersonSafetyStatus.found:
        return 'Found';
      case PersonSafetyStatus.missing:
        return 'Reported Missing';
    }
  }
}
