import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum PersonSafetyStatus { safe, missing }

@immutable
class PersonStatus {
  final String? id;
  final String name;
  final int age;
  final PersonSafetyStatus status;
  final String lastKnownLocation;
  final String submittedBy;
  final DateTime timestamp;

  const PersonStatus({
    this.id,
    required this.name,
    required this.age,
    required this.status,
    required this.lastKnownLocation,
    required this.submittedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'status': status.name,
      'lastKnownLocation': lastKnownLocation,
      'submittedBy': submittedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // --- FIX: Add this factory constructor ---
  factory PersonStatus.fromMap(Map<String, dynamic> map, String id) {
    return PersonStatus(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      status: PersonSafetyStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => PersonSafetyStatus.missing,
      ),
      lastKnownLocation: map['lastKnownLocation'] ?? '',
      submittedBy: map['submittedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

