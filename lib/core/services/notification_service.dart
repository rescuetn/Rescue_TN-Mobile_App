import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/models/alert_model.dart';

/// A service to manage and broadcast in-app notifications.
/// This simulates receiving real-time push notifications.
class NotificationService {
  // A stream controller allows us to push new alerts into a stream that the app can listen to.
  final _notificationController = StreamController<Alert>.broadcast();

  // The public stream that the UI will listen to.
  Stream<Alert> get notificationStream => _notificationController.stream;

  /// Simulates receiving a new push notification.
  void showInAppNotification(Alert alert) {
    _notificationController.add(alert);
  }

  void dispose() {
    _notificationController.close();
  }
}

// A provider for our new NotificationService.
final notificationServiceProvider = Provider((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

// A stream provider that exposes the notification stream from the service.
// The root of our app will listen to this to show the notification banner.
final notificationStreamProvider = StreamProvider<Alert>((ref) {
  return ref.watch(notificationServiceProvider).notificationStream;
});
