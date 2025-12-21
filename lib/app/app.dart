// ignore_for_file: empty_catches
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/router.dart';
import 'package:rescuetn/app/theme.dart';
import 'package:rescuetn/core/services/notification_service.dart';
import 'package:rescuetn/core/widgets/emergency_overlay.dart';
import 'package:rescuetn/models/alert_model.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/7_alerts/providers/alert_provider.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/core/widgets/task_assignment_overlay.dart';
import 'package:rescuetn/models/task_model.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:rescuetn/models/user_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RescueTNApp extends ConsumerWidget {
  const RescueTNApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Setup notification subscription on auth state changes
    ref.listen(authStateChangesProvider, (previous, next) async {
      if (next.hasValue) {
        final user = next.value;
        if (user != null) {
          try {
            final notificationService = ref.read(notificationServiceProvider);
            await notificationService.subscribeToRoleTopics(user.role);
          } catch (e) {
          }
        } else {
          try {
            if (previous?.hasValue == true && previous?.value != null) {
              final notificationService = ref.read(notificationServiceProvider);
              await notificationService
                  .unsubscribeFromRoleTopics(previous!.value!.role);
            }
          } catch (e) {
          }
        }
      }
    });

    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    // Listen to the notification stream and show banner for relevant alerts
    // Listen to the notification stream and show banner for relevant alerts
    ref.listen(notificationStreamProvider, (_, next) {
      final alert = next.value;
      if (alert != null) {
        // Get current user
        final authState = ref.read(authStateChangesProvider); // Use read to get current state instant

        final user = authState.valueOrNull;
        bool shouldShow = false;
        
        if (user != null) {
          if (alert.isForRole(user.role)) {
            shouldShow = true;
          }
        } else {
             // Show all notifications if not logged in (public mode mostly)
             shouldShow = true;
        }

        if (shouldShow) {
           if (alert.level == AlertLevel.severe) {
             _showEmergencyOverlay(context, ref, alert);
           } else {
             _showNotificationBanner(context, router, alert);
           }
        }
      }
    });

    // Listen to Firestore alerts stream for real-time detection
    ref.listen(alertsStreamProvider, (previous, next) async {
      final alerts = next.valueOrNull ?? [];
      final previousAlerts = previous?.valueOrNull ?? [];
      
      // Get previously seen alert IDs from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final seenIds = prefs.getStringList('seen_alert_ids') ?? [];
      final seenSet = Set<String>.from(seenIds);
      
      // Find new alerts (not in previous list and not in seen set)
      final previousIds = previousAlerts.map((a) => a.id).toSet();
      final newAlerts = alerts.where((alert) => 
        !previousIds.contains(alert.id) && !seenSet.contains(alert.id)
      ).toList();
      
      if (newAlerts.isEmpty) return;
      
      // Get services
      final notificationService = ref.read(notificationServiceProvider);
      final authState = ref.read(authStateChangesProvider);
      final user = authState.valueOrNull;
      
      for (final alert in newAlerts) {
        // Check if alert is for user's role
        bool shouldShow = false;
        if (user != null) {
          shouldShow = alert.isForRole(user.role);
        } else {
          shouldShow = true; // Show all if not logged in
        }
        
        if (shouldShow) {
          // Show local push notification
          await notificationService.showLocalNotification(alert);
          
          // Show in-app overlay for severe alerts
          if (alert.level == AlertLevel.severe) {
            _showEmergencyOverlay(context, ref, alert);
          } else {
            _showNotificationBanner(context, router, alert);
          }
        }
        
        // Mark as seen
        seenSet.add(alert.id);
      }
      
      // Persist seen IDs (keep last 100 to avoid unbounded growth)
      final updatedList = seenSet.toList();
      if (updatedList.length > 100) {
        updatedList.removeRange(0, updatedList.length - 100);
      }
      await prefs.setStringList('seen_alert_ids', updatedList);
    });

    // Listen to task stream for new assignments (volunteers only)
    ref.listen(tasksStreamProvider, (previous, next) async {
      final authState = ref.read(authStateChangesProvider);
      final user = authState.valueOrNull;
      
      // Only show for volunteers
      if (user == null || user.role != UserRole.volunteer) return;
      
      final tasks = next.valueOrNull ?? [];
      final previousTasks = previous?.valueOrNull ?? [];
      
      // Get previously seen task IDs
      final prefs = await SharedPreferences.getInstance();
      final seenTaskIds = prefs.getStringList('seen_task_ids') ?? [];
      final seenSet = Set<String>.from(seenTaskIds);
      
      // Find tasks assigned to this volunteer
      final myTasks = tasks.where((t) =>
        t.assignedTo == user.uid ||
        t.assignedTo == user.email ||
        (user.fullName != null && t.assignedTo == user.fullName)
      ).toList();
      
      final previousIds = previousTasks.map((t) => t.id).toSet();
      final newTasks = myTasks.where((task) =>
        !previousIds.contains(task.id) && !seenSet.contains(task.id)
      ).toList();
      
      if (newTasks.isEmpty) return;
      
      final notificationService = ref.read(notificationServiceProvider);
      
      for (final task in newTasks) {
        // Show local notification
        await notificationService.showTaskNotification(
          task.id,
          task.title,
          task.description,
          task.severity == Severity.high ? 'high' : 'normal',
        );
        
        // Show overlay for high severity tasks
        if (task.severity == Severity.high) {
          _showTaskAssignmentOverlay(context, ref, task);
        }
        
        // Mark as seen
        seenSet.add(task.id);
      }
      
      // Persist seen IDs
      final updatedList = seenSet.toList();
      if (updatedList.length > 100) {
        updatedList.removeRange(0, updatedList.length - 100);
      }
      await prefs.setStringList('seen_task_ids', updatedList);
    });

    return MaterialApp.router(
      title: 'RescueTN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ta', ''),
      ],
    );
  }

  /// Show notification banner at the top with theme-aware colors
  void _showNotificationBanner(
      BuildContext context, GoRouter router, dynamic alert) {
    final currentContext = router.routerDelegate.navigatorKey.currentContext;
    if (currentContext != null) {
      // Clear any existing banners first
      ScaffoldMessenger.of(currentContext).clearMaterialBanners();

      // Get theme
      final isDarkMode = Theme.of(currentContext).brightness == Brightness.dark;

      // Get color and icon based on severity with theme awareness
      Color bannerColor;
      Color accentColor;
      IconData bannerIcon;
      Color textColor;

      if (alert.level == AlertLevel.info) {
        bannerColor =
            isDarkMode ? Colors.blue.shade900 : Colors.blue.shade700;
        accentColor =
            isDarkMode ? Colors.blue.shade400 : Colors.blue.shade300;
        bannerIcon = Icons.info_rounded;
        textColor = Colors.white;
      } else if (alert.level == AlertLevel.warning) {
        bannerColor =
            isDarkMode ? Colors.orange.shade900 : Colors.orange.shade700;
        accentColor =
            isDarkMode ? Colors.orange.shade400 : Colors.amber.shade300;
        bannerIcon = Icons.warning_amber_rounded;
        textColor = Colors.white;
      } else if (alert.level == AlertLevel.severe) {
        bannerColor = isDarkMode ? Colors.red.shade900 : Colors.red.shade700;
        accentColor = isDarkMode ? Colors.red.shade400 : Colors.red.shade300;
        bannerIcon = Icons.error_rounded;
        textColor = Colors.white;
      } else {
        bannerColor =
            isDarkMode ? Colors.indigo.shade900 : Colors.indigo.shade700;
        accentColor =
            isDarkMode ? Colors.indigo.shade400 : Colors.indigo.shade300;
        bannerIcon = Icons.notifications_active_rounded;
        textColor = Colors.white;
      }

      // Show enhanced notification banner with gradient
      ScaffoldMessenger.of(currentContext).showMaterialBanner(
        MaterialBanner(
          padding: const EdgeInsets.all(16),
          backgroundColor: bannerColor,
          forceActionsBelow: false,
          elevation: 8,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(bannerIcon, color: accentColor, size: 24),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (alert.message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              alert.message,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.85),
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _getLevelString(alert.level).toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'VIEW',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(currentContext)
                    .hideCurrentMaterialBanner();
                // Navigate to alerts screen
                router.go('/alerts');
              },
            ),
            TextButton(
                child: Text(
                  'DISMISS',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(currentContext)
                      .hideCurrentMaterialBanner();
                }),
          ],
        ),
      );
    }
  }

  void _showEmergencyOverlay(BuildContext context, WidgetRef ref, Alert alert) {
     // Use the navigator key to get the safest context for overlay
    final navigatorState = ref.read(routerProvider).routerDelegate.navigatorKey.currentState;
    
    if (navigatorState != null) {
      showDialog(
        context: navigatorState.context,
        barrierDismissible: false, // User must acknowledge
        barrierColor: Colors.black.withValues(alpha: 0.8), // Darken background
        builder: (context) => EmergencyOverlay(
          alert: alert,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  String _getLevelString(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return 'info';
      case AlertLevel.warning:
        return 'warning';
      case AlertLevel.severe:
        return 'severe';
    }
  }

  void _showTaskAssignmentOverlay(BuildContext context, WidgetRef ref, Task task) {
    final navigatorState = ref.read(routerProvider).routerDelegate.navigatorKey.currentState;
    final router = ref.read(routerProvider);
    
    if (navigatorState != null) {
      showDialog(
        context: navigatorState.context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (dialogContext) => TaskAssignmentOverlay(
          task: task,
          onDismiss: () => Navigator.of(dialogContext).pop(),
          onViewTask: () {
            Navigator.of(dialogContext).pop();
            router.go('/tasks/${task.id}');
          },
        ),
      );
    }
  }
}
