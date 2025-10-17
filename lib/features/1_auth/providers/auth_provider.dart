import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/auth_service.dart';
import 'package:rescuetn/features/1_auth/repository/auth_repository.dart';
import 'package:rescuetn/models/user_model.dart';

/// Riverpod providers for handling authentication logic and state.
/// This version is configured to use the LIVE Firebase backend.

// Provider for the raw FirebaseAuth instance.
final firebaseAuthProvider =
Provider<auth.FirebaseAuth>((ref) => auth.FirebaseAuth.instance);

// Provider for the AuthService itself, pointing to the live Firebase implementation.
final authRepositoryProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService(ref);
});

/// A StreamProvider that listens to the live authentication state from Firebase.
/// This is the single source of truth for the user's login state. The router
/// watches this provider's ".stream" property to know when to refresh.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authRepositoryProvider);
  return authService.authStateChanges;
});

