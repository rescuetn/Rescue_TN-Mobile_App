import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/router.dart';
import 'package:rescuetn/app/theme.dart';
import 'package:rescuetn/core/services/notification_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';

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
            print('✅ User subscribed to ${user.role.name} notifications');
          } catch (e) {
            print('❌ Error subscribing to notifications: $e');
          }
        } else {
          try {
            if (previous?.hasValue == true && previous?.value != null) {
              final notificationService = ref.read(notificationServiceProvider);
              await notificationService
                  .unsubscribeFromRoleTopics(previous!.value!.role);
              print('✅ User unsubscribed from notifications');
            }
          } catch (e) {
            print('❌ Error unsubscribing from notifications: $e');
          }
        }
      }
    });

    final router = ref.watch(routerProvider);

    // Listen to the notification stream and show banner for relevant alerts
    ref.listen(notificationStreamProvider, (_, next) {
      final alert = next.value;
      if (alert != null) {
        // Get current user
        final authState = ref.watch(authStateChangesProvider);

        authState.whenData((user) {
          if (user != null) {
            // Only show notification if it's for the user's role
            if (alert.isForRole(user.role)) {
              _showNotificationBanner(context, router, alert);
            }
          } else {
            // Show all notifications if not logged in
            _showNotificationBanner(context, router, alert);
          }
        });
      }
    });

    return MaterialApp.router(
      title: 'RescueTN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
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

      switch (alert.level.name) {
        case 'info':
          bannerColor =
              isDarkMode ? Colors.blue.shade900 : Colors.blue.shade700;
          accentColor =
              isDarkMode ? Colors.blue.shade400 : Colors.blue.shade300;
          bannerIcon = Icons.info_rounded;
          textColor = Colors.white;
          break;
        case 'warning':
          bannerColor =
              isDarkMode ? Colors.orange.shade900 : Colors.orange.shade700;
          accentColor =
              isDarkMode ? Colors.orange.shade400 : Colors.amber.shade300;
          bannerIcon = Icons.warning_amber_rounded;
          textColor = Colors.white;
          break;
        case 'severe':
          bannerColor = isDarkMode ? Colors.red.shade900 : Colors.red.shade700;
          accentColor = isDarkMode ? Colors.red.shade400 : Colors.red.shade300;
          bannerIcon = Icons.error_rounded;
          textColor = Colors.white;
          break;
        default:
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
              color: accentColor.withOpacity(0.3),
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
                                color: textColor.withOpacity(0.85),
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
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      alert.level.name.toUpperCase(),
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
                backgroundColor: accentColor.withOpacity(0.2),
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
                    color: textColor.withOpacity(0.7),
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
}
