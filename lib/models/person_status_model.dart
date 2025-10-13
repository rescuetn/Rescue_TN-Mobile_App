import 'package:flutter/foundation.dart';

enum PersonSafetyStatus { safe, missing }

@immutable
class PersonStatus {
  final String id;
  final String name;
  final int age;
  final PersonSafetyStatus status;
  final String lastKnownLocation;
  final String submittedBy; // User's email or ID
  // final String imageUrl; // In a real app, this would be a URL

  const PersonStatus({
    required this.id,
    required this.name,
    required this.age,
    required this.status,
    required this.lastKnownLocation,
    required this.submittedBy,
  });
}
