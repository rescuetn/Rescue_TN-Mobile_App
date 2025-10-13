import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/1_auth/screens/login_screen.dart';
import 'package:rescuetn/features/1_auth/screens/profile_screen.dart';
import 'package:rescuetn/features/1_auth/screens/register_screen.dart';
import 'package:rescuetn/features/2_dashboard/screens/public_dashboard_screen.dart';
import 'package:rescuetn/features/2_dashboard/screens/volunteer_dashboard_screen.dart';
import 'package:rescuetn/features/3_incident_reporting/screens/report_incident_screen.dart';
import 'package:rescuetn/features/4_shelter_locator/screens/shelter_map_screen.dart';
import 'package:rescuetn/features/5_task_management/screens/task_details_screen.dart';
import 'package:rescuetn/features/7_alerts/screens/alert_screen.dart';
import 'package:rescuetn/features/8_person_registry/screens/add_person_status_form_screen.dart';
import 'package:rescuetn/features/8_person_registry/screens/person_registry_screen.dart';
import 'package:rescuetn/models/user_model.dart';

/// This provider creates and configures the GoRouter for the application.
///
/// This version is integrated with our dummy authentication system (`userStateProvider`)
/// and implements role-based routing to direct users to the appropriate dashboard.
final routerProvider = Provider<GoRouter>((ref) {
  // We watch our simple state provider to listen for login/logout changes.
  final userState = ref.watch(userStateProvider);

  return GoRouter(
    // The app now starts at the login screen for new or logged-out users.
    initialLocation: '/login',

    // Define all the routes for the application.
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          // --- ROLE-BASED ROUTING LOGIC ---
          // Here, we check the user's role and return the correct dashboard.
          if (userState?.role == UserRole.volunteer) {
            return const VolunteerDashboardScreen();
          }
          // Default to the Public Dashboard for public users or if role is null.
          return const PublicDashboardScreen();
        },
      ),
      GoRoute(
        path: '/report-incident',
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/shelter-map',
        builder: (context, state) => const ShelterMapScreen(),
      ),
      GoRoute(
        path: '/task-details',
        builder: (context, state) => const TaskDetailsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      // --- ROUTES FOR PERSON REGISTRY FEATURE ---
      GoRoute(
        path: '/person-registry',
        builder: (context, state) => const PersonRegistryScreen(),
      ),
      GoRoute(
        path: '/add-person-status',
        builder: (context, state) => const AddPersonStatusScreen(),
      ),
    ],

    // The redirect logic ensures that users are always on the correct screen
    // based on their authentication state.
    redirect: (context, state) {
      final user = ref.read(userStateProvider);
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // Case 1: User is not logged in.
      if (user == null) {
        // If they are already on an authentication screen, do nothing.
        // Otherwise, redirect them to the login screen.
        return isAuthRoute ? null : '/login';
      }

      // Case 2: User is logged in.
      // If they try to access an auth screen (like login), redirect them home.
      if (isAuthRoute) {
        return '/home';
      }

      // No redirect needed.
      return null;
    },
  );
});

