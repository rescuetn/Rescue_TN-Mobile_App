// ignore_for_file: empty_catches
import 'dart:async';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rescuetn/models/alert_model.dart';
import 'package:rescuetn/models/user_model.dart';

/// A service to manage Firebase Cloud Messaging (FCM) notifications
/// and broadcast them to the app via streams.
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

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
      // ignore: unused_local_variable
      final NotificationSettings settings =
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
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmTokenController.add(newToken);
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

      // Initialize local notifications
      await _initializeLocalNotifications();  
    } catch (e) {
    }
  }

  /// Initialize flutter_local_notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap - can navigate to alerts screen
      },
    );

    // Create high-importance notification channel for Android
    const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
      'emergency_alerts',
      'Emergency Alerts',
      description: 'Critical alerts for emergencies',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);
  }

  /// Handle foreground notifications (app is open)
  void _handleForegroundNotification(RemoteMessage message) {

    // Create Alert from FCM message
    final alert = Alert.fromFCM(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );

    // Show system notification
    showLocalNotification(alert);

    // Broadcast to listeners (for in-app overlay)
    _notificationController.add(alert);
  }

  /// Show a local system notification (public for external use)
  Future<void> showLocalNotification(Alert alert) async {
    // Determine notification priority based on alert level
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_alerts',
      'Emergency Alerts',
      channelDescription: 'Critical alerts for emergencies',
      importance: alert.level == AlertLevel.severe ? Importance.max : Importance.high,
      priority: alert.level == AlertLevel.severe ? Priority.max : Priority.high,
      ticker: alert.title,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: alert.level == AlertLevel.severe
          ? const Color(0xFFD32F2F) // Red for severe
          : (alert.level == AlertLevel.warning
              ? const Color(0xFFFFA000) // Orange for warning
              : const Color(0xFF1976D2)), // Blue for info
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      alert.id.hashCode, // Unique ID based on alert ID
      alert.title,
      alert.message,
      notificationDetails,
      payload: alert.actionUrl,
    );
  }

  /// Show a local notification for task assignments
  Future<void> showTaskNotification(String taskId, String title, String description, String severity) async {
    final isHighPriority = severity.toLowerCase() == 'high';
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_assignments',
      'Task Assignments',
      channelDescription: 'Notifications for new task assignments',
      importance: isHighPriority ? Importance.max : Importance.high,
      priority: isHighPriority ? Priority.max : Priority.high,
      ticker: 'New Task: $title',
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: isHighPriority
          ? const Color(0xFFFF9800) // Orange for urgent
          : const Color(0xFF1976D2), // Blue for normal
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      taskId.hashCode,
      '📋 New Task: $title',
      description.isNotEmpty ? description : 'You have been assigned a new task.',
      notificationDetails,
      payload: '/tasks/$taskId',
    );
  }

  /// Handle notification tap (notification opened)
  void _handleNotificationTap(RemoteMessage message) {

    // You can navigate to specific screens based on actionUrl
    final actionUrl = message.data['actionUrl'];
    if (actionUrl != null) {
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
    } catch (e) {
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
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

    } catch (e) {
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

    } catch (e) {
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
