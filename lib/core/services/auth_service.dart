import 'package:rescuetn/models/user_model.dart';

/// An abstract class defining the contract for all authentication services.
///
/// This is a core part of our app's architecture. By depending on this
/// abstract class rather than a concrete implementation like Firebase, we make
/// our app more modular, flexible, and easier to test. It allows us to easily
/// swap out the entire authentication backend (e.g., from our fake service
/// to the real Firebase service) without changing any of the UI code.
abstract class AuthService {
  /// A stream that emits the current [AppUser] when the authentication
  /// state changes. Emits `null` if the user is signed out.
  /// This is the primary way the app should listen for auth state.
  Stream<AppUser?> get authStateChanges;

  /// A synchronous getter for the currently signed-in [AppUser].
  /// May be `null` if no user is signed in.
  AppUser? get currentUser;

  /// Signs in a user with their email/phone and password.
  /// Accepts either email address or phone number as identifier.
  /// Returns the signed-in [AppUser] on success.
  /// Throws an exception on failure (e.g., wrong password).
  Future<AppUser> signInWithEmailAndPassword({
    required String emailOrPhone,
    required String password,
  });

  /// Creates a new user account with the given email, password, and role.
  /// Optionally accepts [skills] for volunteer accounts and [district] for location.
  /// Throws an exception on failure (e.g., email already in use).
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
    required String phoneNumber,
    String? address,
    String? district,
    int? age,
    required UserRole role,
    List<String>? skills,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Sends a password reset link to the given email address.
  /// Throws an exception if the email is not found or another error occurs.
  Future<void> sendPasswordResetEmail({required String email});

  /// Changes the current user's password.
  /// Requires the current password and new password.
  /// Throws an exception on failure.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}