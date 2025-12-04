import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rescuetn/app/app.dart';
import 'package:rescuetn/core/services/notification_service.dart';

/// This is the main entry point of the application.
/// Its primary responsibilities are:
/// 1. Initializing essential services like Firebase and Hive.
/// 2. Setting up FCM for push notifications.
/// 3. Setting up the root of the state management solution (ProviderScope for Riverpod).
/// 4. Running the main application widget (RescueTNApp).

Future<void> main() async {
  // This is required to use platform channels before runApp() is called,
  // which is necessary for Firebase and Hive initialization.
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize Hive for local caching ---
  // This sets up the necessary directories on the device to store the database.
  // It should be called before any Hive operations are performed.
  await Hive.initFlutter();

  // Initialize Firebase for the application.
  await Firebase.initializeApp();

  // Initialize FCM notification service
  // This must be done after Firebase is initialized
  final container = ProviderContainer();
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize();

  // ProviderScope is the widget that stores the state of all our providers.
  // Wrapping the entire app with it allows any widget to access the providers.
  runApp(const ProviderScope(
    child: RescueTNApp(),
  ));
}
