import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/router.dart';
import 'package:rescuetn/app/theme.dart';

/// This is the root widget of the entire application.
/// It configures the MaterialApp, which is the main building block for a Flutter app.
/// Here we connect our custom theme and the navigation router.

class RescueTNApp extends ConsumerWidget {
  const RescueTNApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the routerProvider to get the configured GoRouter instance.
    final router = ref.watch(routerProvider);

    // We use MaterialApp.router to integrate with our GoRouter configuration.
    return MaterialApp.router(
      title: 'RescueTN',
      debugShowCheckedModeBanner: false, // Hides the debug banner in the corner
      theme: AppTheme.lightTheme, // Apply our custom light theme

      // The routerConfig tells the MaterialApp how to handle navigation.
      routerConfig: router,
    );
  }
}

