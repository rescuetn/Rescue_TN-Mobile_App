import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/auth_service.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/features/1_auth/repository/auth_repository.dart';
import 'package:rescuetn/models/user_model.dart';

/// Riverpod providers for handling authentication logic and state.
/// This version is configured to use the LIVE Firebase backend with support
/// for user roles and volunteer skills.

// Provider for the raw FirebaseAuth instance.
final firebaseAuthProvider = Provider<auth.FirebaseAuth>((ref) => auth.FirebaseAuth.instance);

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

/// StateNotifierProvider for managing user profile data during registration.
/// This allows the RegisterScreen to access and update user information before
/// the account creation is complete.
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

/// Model to hold user profile data during the registration process
class UserProfile {
  final String name;
  final String email;
  final UserRole role;
  final List<String>? skills; // For volunteers

  UserProfile({
    this.name = '',
    this.email = '',
    this.role = UserRole.public,
    this.skills,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    UserRole? role,
    List<String>? skills,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      skills: skills ?? this.skills,
    );
  }
}

/// StateNotifier for managing user profile updates during registration
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updateRole(UserRole role) {
    state = state.copyWith(role: role);
  }

  void updateSkills(List<String> skills) {
    state = state.copyWith(skills: skills);
  }

  void reset() {
    state = UserProfile();
  }
}

/// Provider to check if a user is currently authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider to get the current authenticated user
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider to check if the current user is a volunteer
final isVolunteerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == UserRole.volunteer;
});

/// Provider for updating volunteer status in Firebase
/// Usage: ref.read(updateVolunteerStatusProvider(newStatus))
final updateVolunteerStatusProvider = FutureProvider.family<void, VolunteerStatus>((ref, newStatus) async {
  final authService = ref.read(authRepositoryProvider);
  final databaseService = ref.read(databaseServiceProvider);

  final currentUser = authService.currentUser;
  if (currentUser != null) {
    final updatedUser = currentUser.copyWith(status: newStatus);
    await databaseService.updateUserRecord(updatedUser);
  }
});

/// Provider to get current volunteer status
final currentVolunteerStatusProvider = Provider<VolunteerStatus?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.status;
});

/// Provider to check if current user is available
final isVolunteerAvailableProvider = Provider<bool>((ref) {
  final status = ref.watch(currentVolunteerStatusProvider);
  return status == VolunteerStatus.available;
});

/// Provider to check if current user is deployed
final isVolunteerDeployedProvider = Provider<bool>((ref) {
  final status = ref.watch(currentVolunteerStatusProvider);
  return status == VolunteerStatus.deployed;
});

/// Provider to check if current user is unavailable
final isVolunteerUnavailableProvider = Provider<bool>((ref) {
  final status = ref.watch(currentVolunteerStatusProvider);
  return status == VolunteerStatus.unavailable;
});