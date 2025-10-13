import 'dart:async';
import 'package:rescuetn/core/services/auth_service.dart';
import 'package:rescuetn/models/user_model.dart';

/// This file contains the FAKE implementation of our AuthService.
/// It is used for development and demo purposes, allowing the app to
/// function without a live Firebase connection.
///
/// The active implementation is determined by the `authRepositoryProvider`
/// in `lib/features/1_auth/providers/auth_provider.dart`.

class FakeAuthService implements AuthService {
  // Use a StreamController to properly simulate real-time auth state changes.
  final _authStateController = StreamController<AppUser?>.broadcast();

  final Map<String, AppUser> _dummyUsers = {
    'public@test.com': AppUser(
      uid: 'dummy_public_uid',
      email: 'public@test.com',
      role: UserRole.public,
    ),
    'volunteer@test.com': AppUser(
      uid: 'dummy_volunteer_uid',
      email: 'volunteer@test.com',
      role: UserRole.volunteer,
    ),
  };

  AppUser? _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // In a real app, you would add the new user. Here, we just simulate success.
    print('Fake user created for $email');
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    if (password != 'password') {
      throw Exception('Wrong password. Please use "password".');
    }
    if (_dummyUsers.containsKey(email)) {
      _currentUser = _dummyUsers[email];
      _authStateController.add(_currentUser); // Notify listeners of the new state
      return _currentUser!;
    }
    throw Exception('User not found. Try public@test.com or volunteer@test.com');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null); // Notify listeners that user signed out
  }
}

