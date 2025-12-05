import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/1_auth/screens/login_screen.dart';
import 'package:rescuetn/features/1_auth/screens/profile_screen.dart';
import 'package:rescuetn/features/1_auth/screens/register_screen.dart';
import 'package:rescuetn/features/1_auth/screens/edit_profile_screen.dart';
import 'package:rescuetn/features/1_auth/screens/change_password_screen.dart';
import 'package:rescuetn/features/1_auth/screens/forgot_password_screen.dart';
import 'package:rescuetn/features/1_auth/screens/help_center_screen.dart';
import 'package:rescuetn/features/1_auth/screens/privacy_policy_screen.dart';
import 'package:rescuetn/features/1_auth/screens/preferences_screen.dart';
import 'package:rescuetn/features/2_dashboard/screens/public_dashboard_screen.dart';
import 'package:rescuetn/features/2_dashboard/screens/volunteer_dashboard_screen.dart';
import 'package:rescuetn/features/3_incident_reporting/screens/report_incident_screen.dart';
import 'package:rescuetn/features/4_shelter_locator/screens/shelter_map_screen.dart';
import 'package:rescuetn/features/5_task_management/screens/task_details_screen.dart';
// --- CORRECTED IMPORTS ---
import 'package:rescuetn/features/6_preparedness/screens/preparedness_plan_screen.dart';
import 'package:rescuetn/features/7_alerts/screens/alert_screen.dart';
import 'package:rescuetn/features/8_person_registry/screens/add_person_status_form_screen.dart';
import 'package:rescuetn/features/8_person_registry/screens/person_registry_screen.dart';
import 'package:rescuetn/features/9_heatmap/screens/heatmap_screen.dart';
import 'package:rescuetn/models/user_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable:
    GoRouterRefreshStream(ref.watch(authStateChangesProvider.stream)),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final user = authState.value;
          if (user?.role == UserRole.volunteer) {
            return const VolunteerDashboardScreen();
          }
          return const PublicDashboardScreen();
        },
      ),
      GoRoute(path: '/report-incident', builder: (context, state) => const ReportIncidentScreen()),
      GoRoute(path: '/shelter-map', builder: (context, state) => const ShelterMapScreen()),
      GoRoute(path: '/task-details', builder: (context, state) => const TaskDetailsScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/help-center', builder: (context, state) => const HelpCenterScreen()),
      GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/preferences', builder: (context, state) => const PreferencesScreen()),
      GoRoute(path: '/alerts', builder: (context, state) => const AlertsScreen()),
      GoRoute(path: '/person-registry', builder: (context, state) => const PersonRegistryScreen()),
      GoRoute(path: '/preparedness-plan', builder: (context, state) => const PreparednessPlanScreen()),
      GoRoute(path: '/add-person-status', builder: (context, state) => const AddPersonStatusScreen()),
      GoRoute(path: '/heatmap', builder: (context, state) => const HeatmapScreen()),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' || 
          state.matchedLocation == '/register' || 
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute) {
        return '/home';
      }
      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
