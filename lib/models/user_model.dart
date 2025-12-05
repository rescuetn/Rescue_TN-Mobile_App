/// A data model representing a user in the application.
/// It includes methods for serializing to and from Firestore.
import 'package:flutter/material.dart';
class AppUser {
  final String uid;
  final String email;
  final String phoneNumber;
  final String? address;
  final int? age;
  final String? profilePhotoUrl;
  final UserRole role;
  final List<String>? skills;
  final VolunteerStatus? status;

  AppUser({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.age,
    this.profilePhotoUrl,
    required this.role,
    this.skills,
    this.status,
  });

  /// Converts an [AppUser] instance into a map (JSON format) for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'age': age,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role.name,
      'skills': skills,
      'status': status?.name ?? VolunteerStatus.available.name,
    };
  }

  /// Creates an [AppUser] instance from a Firestore document map.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'],
      age: map['age'] != null ? (map['age'] is int ? map['age'] : int.tryParse(map['age'].toString())) : null,
      profilePhotoUrl: map['profilePhotoUrl'],
      // Convert the string from Firestore back to a UserRole enum.
      role: UserRole.values.firstWhere(
            (e) => e.name == map['role'],
        orElse: () => UserRole.public,
      ),
      // Convert skills list from Firestore
      skills: map['skills'] != null ? List<String>.from(map['skills']) : null,
      // Convert status string from Firestore back to enum
      status: map['status'] != null
          ? VolunteerStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => VolunteerStatus.available,
      )
          : VolunteerStatus.available,
    );
  }

  /// Creates a copy of this user with optional field overrides
  AppUser copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? address,
    int? age,
    String? profilePhotoUrl,
    UserRole? role,
    List<String>? skills,
    VolunteerStatus? status,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      age: age ?? this.age,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      status: status ?? this.status,
    );
  }
}

/// Defines the possible roles a user can have within the app.
enum UserRole {
  public,
  volunteer,
}

/// Defines the availability status for volunteers
enum VolunteerStatus {
  available('Available', 0xFF4CAF50),
  deployed('Deployed', 0xFFFFA726),
  unavailable('Unavailable', 0xFFEF5350);

  final String label;
  final int colorValue;

  const VolunteerStatus(this.label, this.colorValue);

  Color get color => Color(colorValue);
}



extension VolunteerStatusExtension on VolunteerStatus {
  IconData get icon {
    switch (this) {
      case VolunteerStatus.available:
        return Icons.check_circle;
      case VolunteerStatus.deployed:
        return Icons.location_on;
      case VolunteerStatus.unavailable:
        return Icons.cancel;
    }
  }

  String get description {
    switch (this) {
      case VolunteerStatus.available:
        return 'Ready to accept tasks';
      case VolunteerStatus.deployed:
        return 'Currently on a task';
      case VolunteerStatus.unavailable:
        return 'Not available for tasks';
    }
  }
}