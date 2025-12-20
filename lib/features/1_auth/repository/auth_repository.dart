import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  @override
  AppUser? get currentUser {
    // WARNING: This synchronous getter CANNOT fetch the user's role from Firestore.
    // It should NOT be used to determine a user's role or access level.
    // Always use the `authStateChanges` stream for the complete, reliable user profile.
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    // The role and phone number here are just placeholders and are not accurate.
    // This should only be used for basic checks, not for complete user data.
    return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        phoneNumber:
            '', // Placeholder - actual value should come from Firestore
        role: UserRole.public);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    // This is the reliable, asynchronous way to get the auth state.
    // It maps the Firebase user stream to our custom AppUser stream by fetching
    // the user's role and other data from Firestore.
    // We use asyncExpand to listen to the Firestore stream, providing REAL-TIME updates.
    return _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      // Listen to the Firestore document stream for this user.
      return _databaseService.getUserStream(firebaseUser.uid);
    });
  }

  @override
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
  }) async {
    // 1. Create the user in Firebase Auth with retry logic for reCAPTCHA errors.
    auth.UserCredential? userCredential;
    int retries = 0;
    const maxRetries = 5;

    while (retries < maxRetries) {
      try {
        userCredential = await _firebaseAuth
            .createUserWithEmailAndPassword(
              email: email,
              password: password,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () =>
                  throw TimeoutException('Firebase auth request timed out'),
            );
        break; // Success, exit retry loop
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          rethrow; // Give up after max retries
        }
        // Wait before retrying (exponential backoff: 1s, 2s, 3s, 4s, 5s)
        await Future.delayed(Duration(seconds: retries));
      }
    }

    final firebaseUser = userCredential?.user;
    if (firebaseUser == null) {
      throw Exception('User creation failed, please try again.');
    }
    // 2. Create our custom AppUser object with skills for volunteers.
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      address: address,
      district: district,
      age: age,
      role: role,
      skills: skills, // Include skills for volunteer accounts
    );
    // 3. Save the user's data (including their role and skills) to Firestore.
    await _databaseService.createUserRecord(appUser);
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String emailOrPhone,
    required String password,
  }) async {
    String email;

    // 1. Determine if input is email or phone number
    final isEmail = emailOrPhone.contains('@');

    if (isEmail) {
      // If it's an email, use it directly
      email = emailOrPhone.trim();
    } else {
      // If it's a phone number, find the user's email from Firestore
      final cleanedPhone =
          emailOrPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();

      // Query Firestore to find user by phone number
      final usersSnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanedPhone)
          .limit(1)
          .get();

      // Try different phone number formats to find the user
      final variations = [
        cleanedPhone,
        '+91$cleanedPhone', // Add India country code
        cleanedPhone.startsWith('91')
            ? cleanedPhone.substring(2)
            : '91$cleanedPhone',
      ];

      // First try the exact match
      String? foundEmail;
      if (usersSnapshot.docs.isNotEmpty) {
        final userData = usersSnapshot.docs.first.data();
        foundEmail = userData['email'] as String?;
      }

      // If not found, try variations
      if (foundEmail == null || foundEmail.isEmpty) {
        for (final variation in variations) {
          if (variation == cleanedPhone) continue; // Already tried

          final altSnapshot = await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: variation)
              .limit(1)
              .get();

          if (altSnapshot.docs.isNotEmpty) {
            final userData = altSnapshot.docs.first.data();
            foundEmail = userData['email'] as String?;
            if (foundEmail != null && foundEmail.isNotEmpty) {
              break;
            }
          }
        }
      }

      if (foundEmail == null || foundEmail.isEmpty) {
        throw Exception(
            'No account found with this phone number. Please check and try again.');
      }

      email = foundEmail;
    }

    // 2. Sign in with Firebase Auth using the email
    auth.UserCredential? userCredential;
    int retries = 0;
    const maxRetries = 5;

    while (retries < maxRetries) {
      try {
        userCredential = await _firebaseAuth
            .signInWithEmailAndPassword(
              email: email,
              password: password,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () =>
                  throw TimeoutException('Firebase auth request timed out'),
            );
        break; // Success, exit retry loop
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          rethrow; // Give up after max retries
        }
        // Wait before retrying (exponential backoff: 1s, 2s, 3s, 4s, 5s)
        await Future.delayed(Duration(seconds: retries));
      }
    }

    final firebaseUser = userCredential?.user;
    if (firebaseUser == null) {
      throw Exception('Sign in failed.');
    }
    // 3. Fetch the complete user profile from Firestore to get their role and skills.
    final appUser = await _databaseService.getUserRecord(firebaseUser.uid);
    if (appUser == null) {
      throw Exception(
          'User data not found in database. Please contact support.');
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    if (user.email == null) {
      throw Exception('User email is not available.');
    }

    // Re-authenticate user with current password
    final credential = auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      // Update password
      await user.updatePassword(newPassword);
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect.');
      } else if (e.code == 'weak-password') {
        throw Exception(
            'New password is too weak. Please choose a stronger password.');
      } else {
        throw Exception('Failed to change password: ${e.message}');
      }
    }
  }
}
