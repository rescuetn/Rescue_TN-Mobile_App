# 🔔 FCM Notification System Implementation Guide

## Overview

Your RescueTN mobile app now has a **complete Firebase Cloud Messaging (FCM) notification system** with **role-based alert delivery**. This guide explains the implementation and how to use it.

---

## Architecture

```
Government Dashboard (Admin sends alert)
           ↓
    Alert in Firestore (with targetRoles)
           ↓
    FCM Sends to subscribed topics
           ↓
    Mobile App receives notification
           ↓
  Role-based filtering applied
           ↓
  Notification displayed to user
           ↓
  Alert synced to Firestore user's alerts
```

---

## What's Been Implemented

### 1. Enhanced Alert Model (`lib/models/alert_model.dart`)
- Added role-based targeting: `targetRoles: List<String>?`
- Added `isForRole(UserRole)` method to check if alert is for user
- Added `isRead` field to track notification status
- Added `imageUrl` and `actionUrl` fields for rich notifications
- Added `fromFCM()` factory constructor to parse FCM messages
- Added `toMap()` for Firestore serialization

### 2. Enhanced Notification Service (`lib/core/services/notification_service.dart`)
- **FCM Integration**: Full Firebase Cloud Messaging setup
- **Foreground Handling**: Shows notifications while app is open
- **Background Handling**: Processes notifications in background
- **Topic Subscription**: Auto-subscribes to role-based topics
- **Token Management**: Tracks and updates FCM tokens
- **Stream Broadcasting**: Real-time notification streams

### 3. Enhanced Database Service (`lib/core/services/database_service.dart`)
- `addAlert()`: Add new alert to Firestore
- `updateAlertStatus()`: Mark alerts as read

### 4. Notification Providers (`lib/features/7_alerts/providers/alert_notification_provider.dart`)
- `userAlertsProvider`: Filters alerts based on user role
- `unreadAlertsCountProvider`: Tracks unread count
- `recentAlertsProvider`: Gets last 5 alerts
- `alertNotificationProvider`: Manages alert interactions
- `fcmTokenProvider`: FCM token stream

### 5. Enhanced App Root (`lib/app/app.dart`)
- Auto-subscribes to role-based topics on login
- Auto-unsubscribes on logout
- Enhanced notification banner with severity colors
- Role-based notification filtering

### 6. FCM Initialization (`lib/main.dart`)
- Initialize notification service after Firebase
- Request notification permissions
- Set up background message handler

### 7. Android Manifest Updates
- Added `POST_NOTIFICATIONS` permission

---

## How It Works

### 1. User Registration/Login
```
User logs in
    ↓
App gets user role (public/volunteer)
    ↓
Subscribe to topics:
   - "all-users" (everyone)
   - "volunteers" (if volunteer)
   - "public-users" (if public)
    ↓
Get FCM token
    ↓
Store FCM token in user preferences
```

### 2. Government Dashboard Sends Alert
```
Admin creates alert:
{
  title: "Flood Warning",
  message: "Heavy rain expected",
  level: "warning",
  targetRoles: ["volunteer", "public"]  // or null for all
}
    ↓
Alert saved to Firestore
    ↓
FCM triggered to send to topic:
   - If targetRoles = ["volunteer"] → send to "volunteers" topic
   - If targetRoles = ["public"] → send to "public-users" topic
   - If targetRoles = null → send to "all-users" topic
```

### 3. Mobile App Receives Notification
```
FCM message received by phone
    ↓
While app is open:
   - Foreground handler processes it
   - Shows material banner
   - Broadcasts to stream
    ↓
While app is closed:
   - Background handler processes it
   - Shows system notification
   - Stores in local cache
    ↓
When app opens:
   - Checks if notification is for user's role
   - Filters and displays
```

---

## Firestore Structure

### Alerts Collection
```json
{
  "title": "Flood Alert",
  "message": "Heavy flooding in downtown",
  "level": "warning",  // info, warning, severe
  "timestamp": "2024-12-03T10:30:00Z",
  "targetRoles": ["volunteer", "public"],  // null = all users
  "imageUrl": "gs://bucket/flood.jpg",  // optional
  "isRead": false,
  "actionUrl": "/alerts"  // optional navigation
}
```

---

## How to Send Notifications from Government Dashboard

### Method 1: Using Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Create new campaign
3. In "Target" section, select topics:
   - "all-users" (everyone)
   - "volunteers" (only volunteers)
   - "public-users" (only public users)

### Method 2: Using Firebase Cloud Function (Recommended)
Create a Cloud Function triggered when alert is added:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendAlertNotification = functions.firestore
  .document('alerts/{alertId}')
  .onCreate(async (snap, context) => {
    const alert = snap.data();
    
    // Determine topics to send to
    let topics = ['all-users'];
    
    if (alert.targetRoles && alert.targetRoles.length > 0) {
      if (alert.targetRoles.includes('volunteer')) {
        topics.push('volunteers');
      }
      if (alert.targetRoles.includes('public')) {
        topics.push('public-users');
      }
    }
    
    // Send to each topic
    for (const topic of topics) {
      await admin.messaging().send({
        topic: topic,
        notification: {
          title: alert.title,
          body: alert.message,
          imageUrl: alert.imageUrl,
        },
        data: {
          alertId: context.params.alertId,
          level: alert.level,
          title: alert.title,
          message: alert.message,
          targetRoles: alert.targetRoles ? alert.targetRoles.join(',') : '',
          imageUrl: alert.imageUrl || '',
          actionUrl: alert.actionUrl || '/alerts',
        },
      });
    }
    
    return null;
  });
```

### Method 3: Using Node.js Script
```javascript
const admin = require('firebase-admin');

admin.initializeApp();

async function sendAlert() {
  const message = {
    topic: 'volunteers',  // or 'public-users' or 'all-users'
    notification: {
      title: 'Emergency Alert',
      body: 'Please evacuate immediately',
    },
    data: {
      alertId: 'alert_123',
      level: 'severe',
      actionUrl: '/alerts',
    },
  };
  
  const response = await admin.messaging().send(message);
  console.log('Successfully sent message:', response);
}

sendAlert();
```

---

## Using Notifications in Mobile App

### 1. Listen to Alerts
```dart
// In your widget
final alerts = ref.watch(userAlertsProvider);

alerts.when(
  data: (alertList) {
    return ListView.builder(
      itemCount: alertList.length,
      itemBuilder: (context, index) {
        final alert = alertList[index];
        return AlertCard(alert: alert);
      },
    );
  },
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### 2. Mark Alert as Read
```dart
final alertNotifier = ref.read(alertNotificationProvider.notifier);
await alertNotifier.markAlertAsRead(alertId);
```

### 3. Get Unread Count
```dart
final unreadCount = ref.watch(unreadAlertsCountProvider);

unreadCount.when(
  data: (count) => Badge(
    label: Text('$count'),
    child: const Icon(Icons.notifications),
  ),
  loading: () => const SizedBox(),
  error: (_, __) => const SizedBox(),
);
```

### 4. Get FCM Token (for admin verification)
```dart
final fcmToken = ref.watch(currentFcmTokenProvider);

fcmToken.when(
  data: (token) => Text('FCM Token: $token'),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

---

## Testing Notifications

### Test 1: Manually Send FCM Message
Using Firebase Console:
1. Go to Messaging → Send your first message
2. Notification title: "Test Alert"
3. Notification text: "This is a test"
4. Target: Select "Topic"
5. Topic name: "all-users"
6. Publish

### Test 2: Send from Code
```dart
// Add to any screen for testing
ElevatedButton(
  onPressed: () {
    // Simulate receiving notification
    final testAlert = Alert(
      id: 'test-alert',
      title: 'Test Notification',
      message: 'This is a test notification',
      level: AlertLevel.warning,
      timestamp: DateTime.now(),
      targetRoles: ['volunteer'],
    );
    
    ref.read(notificationServiceProvider).showInAppNotification(testAlert);
  },
  child: const Text('Test Notification'),
)
```

### Test 3: End-to-End Flow
1. Open app as volunteer user
2. From government dashboard, send alert to "volunteers" topic
3. Verify notification appears on phone
4. Tap notification → Navigate to alerts screen
5. Verify alert is listed

---

## API Reference

### NotificationService
```dart
// Initialize (called in main.dart)
Future<void> initialize()

// Get FCM token
Future<String?> getFCMToken()

// Subscribe/unsubscribe topics
Future<void> subscribeToTopic(String topic)
Future<void> unsubscribeFromTopic(String topic)

// Role-based subscriptions
Future<void> subscribeToRoleTopics(UserRole role)
Future<void> unsubscribeFromRoleTopics(UserRole role)

// Manual notification (in-app)
void showInAppNotification(Alert alert)

// Streams
Stream<Alert> get notificationStream
Stream<String> get fcmTokenStream
```

### Alert Model
```dart
// Create from FCM
Alert.fromFCM(Map<String, dynamic> data, {String? title, String? body})

// Check if for role
bool isForRole(UserRole userRole)

// Copy with modifications
Alert copyWith({...})

// Serialization
Map<String, dynamic> toMap()
```

---

## Troubleshooting

### Issue: Not receiving notifications
**Solution:**
1. Verify FCM token is generated: Check logs for "FCM Token:"
2. Verify topic subscription: Check logs for "Subscribed to topic:"
3. Verify app permissions: Check Android Settings → Notifications

### Issue: Notifications not showing while app open
**Solution:**
The app is working correctly! Foreground notifications show as material banner, not system notification. This is expected behavior.

### Issue: Can't see FCM token
**Solution:**
1. Run `flutter run -v` for verbose logs
2. Look for: `FCM Token: ...`
3. Or add debug screen: `ref.watch(currentFcmTokenProvider)`

### Issue: Permissions denied on Android
**Solution:**
1. Android 13+ requires POST_NOTIFICATIONS permission (already added)
2. Grant permission in app settings
3. Or user grants during first notification

---

## Security Considerations

### Firestore Rules
Update your Firestore security rules:

```javascript
// Alerts can be read by authenticated users
match /alerts/{alertId} {
  allow read: if request.auth != null;
  allow create: if false;  // Only admin/server can create
  allow update: if request.auth.uid == resource.data.createdBy;
}

// Topic subscriptions are automatic based on role
// No special rules needed
```

### Best Practices
1. ✅ Validate alert targetRoles before sending
2. ✅ Use FCM token to verify device ownership
3. ✅ Always authenticate users before subscribing to topics
4. ✅ Log alert delivery for auditing
5. ✅ Rate limit notifications to prevent spam

---

## Role-Based Topic Mapping

| User Role | Topics Subscribed | Receives |
|-----------|-------------------|----------|
| **volunteer** | all-users, volunteers | Alerts for volunteers + all users |
| **public** | all-users, public-users | Alerts for public + all users |
| **admin** | all-users, volunteers, public-users | All alerts |

---

## Next Steps

1. ✅ Test sending notifications from Firebase Console
2. ✅ Verify topics: `all-users`, `volunteers`, `public-users`
3. ✅ Integrate with government dashboard alert creation
4. ✅ Add Cloud Function for automatic topic distribution
5. ✅ Monitor notification delivery in Firebase Console
6. ✅ Collect FCM tokens in admin dashboard for targeted sends

---

## Files Modified

- ✅ `lib/models/alert_model.dart` - Role-based alerts
- ✅ `lib/core/services/notification_service.dart` - FCM integration
- ✅ `lib/core/services/database_service.dart` - Alert operations
- ✅ `lib/app/app.dart` - Auto-subscription on login
- ✅ `lib/main.dart` - FCM initialization
- ✅ `android/app/src/main/AndroidManifest.xml` - Permissions
- ✅ `lib/features/7_alerts/providers/alert_notification_provider.dart` - New providers

---

## Success Criteria

✅ FCM token generated on app start
✅ Topics subscribed: all-users + role-specific
✅ Alerts filtered by user role
✅ Notifications show material banner while app open
✅ Notifications show system notification while app closed
✅ Unread count tracked
✅ Alerts marked as read
✅ Can navigate from notification to alerts screen

You now have a **production-ready notification system** that integrates with your government dashboard! 🚀
