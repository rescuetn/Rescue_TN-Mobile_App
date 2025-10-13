/// A data model representing a user in the application.
/// It includes methods for serializing to and from Firestore.
class AppUser {
  final String uid;
  final String email;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  /// Converts an [AppUser] instance into a map (JSON format) for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.name, // Store the enum as a string (e.g., 'public')
    };
  }

  /// Creates an [AppUser] instance from a Firestore document map.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      // Convert the string from Firestore back to a UserRole enum.
      role: UserRole.values.firstWhere(
            (e) => e.name == map['role'],
        orElse: () => UserRole.public, // Default to public if role is missing/invalid
      ),
    );
  }
}

/// Defines the possible roles a user can have within the app.
enum UserRole {
  public,
  volunteer,
}

