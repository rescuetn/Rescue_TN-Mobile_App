import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/auth_service.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/user_model.dart';

/// This is the concrete implementation of our AuthService using the live Firebase backend.
/// It handles all authentication logic and user data fetching from Firestore.
class FirebaseAuthService implements AuthService {
  final Ref _ref;

  FirebaseAuthService(this._ref);

  // Private getters to easily access Firebase services via their providers.
  auth.FirebaseAuth get _firebaseAuth => _ref.read(firebaseAuthProvider);
  DatabaseService get _databaseService => _ref.read(databaseServiceProvider);

  @override
  AppUser? get currentUser {
    // WARNING: This synchronous getter CANNOT fetch the user's role from Firestore.
    // It should NOT be used to determine a user's role or access level.
    // Always use the `authStateChanges` stream for the complete, reliable user profile.
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    // The role here is just a placeholder and is not accurate.
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '', role: UserRole.public);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    // This is the reliable, asynchronous way to get the auth state.
    // It maps the Firebase user stream to our custom AppUser stream by fetching
    // the user's role and other data from Firestore.
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      // Return the full user profile from our database.
      return await _databaseService.getUserRecord(firebaseUser.uid);
    });
  }

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
    List<String>? skills,
  }) async {
    // 1. Create the user in Firebase Auth.
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('User creation failed, please try again.');
    }
    // 2. Create our custom AppUser object with skills for volunteers.
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: email,
      role: role,
      skills: skills, // Include skills for volunteer accounts
    );
    // 3. Save the user's data (including their role and skills) to Firestore.
    await _databaseService.createUserRecord(appUser);
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // 1. Sign in with Firebase Auth.
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Sign in failed.');
    }
    // 2. Fetch the complete user profile from Firestore to get their role and skills.
    final appUser = await _databaseService.getUserRecord(firebaseUser.uid);
    if (appUser == null) {
      throw Exception('User data not found in database. Please contact support.');
    }
    return appUser;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}