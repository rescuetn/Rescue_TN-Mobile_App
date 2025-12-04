import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/models/alert_model.dart';
import 'package:rescuetn/models/user_model.dart';

/// A service to manage Firebase Cloud Messaging (FCM) notifications
/// and broadcast them to the app via streams.
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Stream controllers for different notification types
  final _notificationController = StreamController<Alert>.broadcast();
  final _fcmTokenController = StreamController<String>.broadcast();

  // Public streams
  Stream<Alert> get notificationStream => _notificationController.stream;
  Stream<String> get fcmTokenStream => _fcmTokenController.stream;

  /// Initialize FCM and set up listeners
  Future<void> initialize() async {
    try {
      // Request user permission for notifications
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get initial FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmTokenController.add(token);
        print('FCM Token: $token');
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmTokenController.add(newToken);
        print('FCM Token Refreshed: $newToken');
        // You should update this token in your Firestore user document
      });

      // Handle foreground messages (app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundNotification(message);
      });

      // Handle background message (app is in background/terminated)
      // Note: This should be a top-level function
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle notification opened (user taps on notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  /// Handle foreground notifications (app is open)
  void _handleForegroundNotification(RemoteMessage message) {
    print('Foreground notification received:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Create Alert from FCM message
    final alert = Alert.fromFCM(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );

    // Broadcast to listeners
    _notificationController.add(alert);
  }

  /// Handle notification tap (notification opened)
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');

    // You can navigate to specific screens based on actionUrl
    final actionUrl = message.data['actionUrl'];
    if (actionUrl != null) {
      print('Action URL: $actionUrl');
      // Navigation will be handled in the app's main widget
    }
  }

  /// Show in-app notification (manual)
  void showInAppNotification(Alert alert) {
    _notificationController.add(alert);
  }

  /// Get current FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe to role-based topics
  Future<void> subscribeToRoleTopics(UserRole role) async {
    try {
      // Subscribe to universal topic
      await subscribeToTopic('all-users');

      // Subscribe to role-specific topic
      switch (role) {
        case UserRole.volunteer:
          await subscribeToTopic('volunteers');
          break;
        case UserRole.public:
          await subscribeToTopic('public-users');
          break;
      }

      print('Subscribed to topics for role: ${role.name}');
    } catch (e) {
      print('Error subscribing to role topics: $e');
    }
  }

  /// Unsubscribe from role-based topics
  Future<void> unsubscribeFromRoleTopics(UserRole role) async {
    try {
      // Optionally unsubscribe from universal topic if needed
      // await unsubscribeFromTopic('all-users');

      switch (role) {
        case UserRole.volunteer:
          await unsubscribeFromTopic('volunteers');
          break;
        case UserRole.public:
          await unsubscribeFromTopic('public-users');
          break;
      }

      print('Unsubscribed from topics for role: ${role.name}');
    } catch (e) {
      print('Error unsubscribing from role topics: $e');
    }
  }

  void dispose() {
    _notificationController.close();
    _fcmTokenController.close();
  }
}

/// Top-level function to handle background messages
/// This must be a top-level function, not a method
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // Here you can update local storage or trigger updates
  // For now, we just log the message
}

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Stream provider for notifications
final notificationStreamProvider = StreamProvider<Alert>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationStream;
});

// Stream provider for FCM tokens
final fcmTokenProvider = StreamProvider<String>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.fcmTokenStream;
});

// Future provider to get current FCM token
final currentFcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getFCMToken();
});
