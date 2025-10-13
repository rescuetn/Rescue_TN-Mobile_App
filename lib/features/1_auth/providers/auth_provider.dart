import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rescuetn/core/services/auth_service.dart';
import 'package:rescuetn/features/1_auth/repository/auth_repository.dart';
import 'package:rescuetn/models/user_model.dart';

/// Riverpod providers for handling authentication logic and state.
///
/// This file is the central switchboard for our authentication system, allowing
/// us to easily toggle between a fake local service and a real Firebase backend.

// 1. Provider for the AuthService itself.
// This is the main switch.
final authRepositoryProvider = Provider<AuthService>((ref) {
  // To use the dummy login, provide the FakeAuthService.
  return FakeAuthService();

  // --- TO SWITCH BACK TO REAL FIREBASE AUTHENTICATION ---
  // Simply comment out the line above and uncomment the line below.
  // return FirebaseAuthService(ref);
});

/// 2. A simple StateProvider to hold the currently logged-in user's state.
///
/// This is used by the dummy auth system. When a user logs in via the
/// FakeAuthService, we manually update this state. The router and UI listen
/// to this provider to react to login/logout events.
final userStateProvider = StateProvider<AppUser?>((ref) => null);

/// 3. A provider for the raw FirebaseAuth instance.
///
/// This is needed by the real `FirebaseAuthService`. It is defined here so that
/// switching between fake and real services is as simple as changing one line
/// in the `authRepositoryProvider` above.
///
/// Riverpod providers are "lazy," so this will not be initialized (and will not
/// try to connect to Firebase) unless it is actively read by `FirebaseAuthService`.
final firebaseAuthProvider =
Provider<auth.FirebaseAuth>((ref) => auth.FirebaseAuth.instance);

