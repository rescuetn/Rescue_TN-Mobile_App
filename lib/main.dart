import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/app.dart';
// import 'package:firebase_core/firebase_core.dart'; // Uncomment once Firebase is set up

/// This is the main entry point of the application.
/// Its primary responsibilities are:
/// 1. Initializing essential services like Firebase (when ready).
/// 2. Setting up the root of the state management solution (ProviderScope for Riverpod).
/// 3. Running the main application widget (RescueTNApp).

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized() is required to use platform channels
  // before runApp() is called, which is necessary for Firebase initialization.
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // ProviderScope is the widget that stores the state of all our providers.
  // Wrapping the entire app with it allows any widget to access the providers.
  runApp(const ProviderScope(
    child: RescueTNApp(),
  ));
}
