import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/auth_service.dart';
import 'package:rescuetn/features/1_auth/repository/auth_repository.dart';
import 'package:rescuetn/models/user_model.dart';

/// Riverpod providers for handling authentication logic and state.
/// This version is configured to use the LIVE Firebase backend.

// 1. A provider for the raw FirebaseAuth instance.
// This is required by the `FirebaseAuthService` to perform authentication operations.
final firebaseAuthProvider =
Provider<auth.FirebaseAuth>((ref) => auth.FirebaseAuth.instance);

// 2. Provider for the AuthService itself.
// By providing FirebaseAuthService, the entire app will now use the real backend.
final authRepositoryProvider = Provider<AuthService>((ref) {
  // The service can access other providers by using the 'ref' object.
  return FirebaseAuthService(ref);
});

/// 3. A StreamProvider that listens to the live authentication state from Firebase.
///
/// This is NOW THE ONLY source of truth for the user's login state. Any widget
/// in the app can watch this provider to get the current user, as well as
/// loading and error states, and will automatically rebuild when the state changes.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authRepositoryProvider);
  return authService.authStateChanges;
});

// The 'userStateProvider' has been removed. It was a useful tool for the
// dummy/hardcoded system, but with a live stream from Firebase, it is no

// longer necessary and creates a redundant source of state. The UI should
// now watch 'authStateChangesProvider' directly.

