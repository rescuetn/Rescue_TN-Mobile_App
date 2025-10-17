import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/router.dart';
import 'package:rescuetn/app/theme.dart';
import 'package:rescuetn/core/services/notification_service.dart';

class RescueTNApp extends ConsumerWidget {
  const RescueTNApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Listen to the notification stream provider.
    // When a new alert is received, this will trigger the listener.
    ref.listen(notificationStreamProvider, (_, next) {
      final alert = next.value;
      if (alert != null) {
        // We need to access the context from the router's navigator key
        // to show the banner overlaying the entire app.
        final currentContext = router.routerDelegate.navigatorKey.currentContext;
        if (currentContext != null) {
          // Clear any existing banners first.
          ScaffoldMessenger.of(currentContext).clearMaterialBanners();

          // Show a MaterialBanner at the top of the screen.
          ScaffoldMessenger.of(currentContext).showMaterialBanner(
            MaterialBanner(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.orange.shade800,
              content: Text(
                alert.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  child:
                  const Text('VIEW', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    ScaffoldMessenger.of(currentContext)
                        .hideCurrentMaterialBanner();
                    // Navigate to the alerts screen when the banner is tapped.
                    router.go('/alerts');
                  },
                ),
                TextButton(
                  child: const Text('DISMISS',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    ScaffoldMessenger.of(currentContext)
                        .hideCurrentMaterialBanner();
                  },
                ),
              ],
            ),
          );
        }
      }
    });

    return MaterialApp.router(
      title: 'RescueTN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

