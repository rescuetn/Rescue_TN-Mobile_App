# 🚀 FCM Notification System - Quick Start Guide

## 5-Minute Setup & Testing

### Prerequisites
- ✅ Flutter app installed
- ✅ Firebase project configured
- ✅ FCM enabled in Firebase Console
- ✅ Google Services JSON added (Android)
- ✅ GoogleService-Info.plist added (iOS)

---

## Step 1: Run the App (2 minutes)

```bash
cd /Users/karthickrajav/Rescue_TN-Mobile_App

# Clean build
flutter clean
flutter pub get

# Run on device or emulator
flutter run
```

**Expected Output:**
```
✅ App starts successfully
✅ No compilation errors
✅ Logs show: "FCM Token: ..."
```

---

## Step 2: Verify FCM Token (1 minute)

In the app logs, look for:
```
I/Flutter: FCM Token: eXFkQWJkWV...
```

If you see this ✅ FCM is working!

**If not:**
- Check internet connection
- Verify Firebase configuration
- Check Google Services JSON/plist files

---

## Step 3: Send Test Notification (2 minutes)

### Via Firebase Console:

1. Go to **Firebase Console** → **Messaging**
2. Click **Send your first message**
3. Fill in:
   - **Notification title:** "Test Alert"
   - **Notification text:** "This is working!"
4. Click **Send test message**
5. Select your device
6. Click **Test**

**Expected:**
- ✅ Notification appears on phone (if app is closed)
- ✅ Material banner appears (if app is open)
- ✅ You can tap to navigate to alerts screen

---

## Step 4: Test Role-Based Filtering (3 minutes)

### Login as Volunteer:
1. Open app
2. Login with volunteer account
3. Check logs for: `"Subscribed to topic: volunteers"`
4. In Firebase Console, send to topic: **"volunteers"**
5. ✅ You should receive it

### Login as Public User:
1. Logout from app
2. Login with public account
3. Check logs for: `"Subscribed to topic: public-users"`
4. In Firebase Console, send to topic: **"public-users"**
5. ✅ You should receive it
6. In Firebase Console, send to topic: **"volunteers"** (different topic)
7. ❌ You should NOT receive it

---

## Step 5: Manual Topic Test (Advanced)

If you have Firebase CLI installed:

```bash
# Login to Firebase
firebase login

# Send to volunteers topic
firebase messaging:send '{
  "notification": {
    "title": "Volunteer Alert",
    "body": "This is for volunteers only"
  },
  "topic": "volunteers"
}'

# Send to public-users topic
firebase messaging:send '{
  "notification": {
    "title": "Public Alert",
    "body": "This is for public users"
  },
  "topic": "public-users"
}'

# Send to all-users topic
firebase messaging:send '{
  "notification": {
    "title": "General Alert",
    "body": "This is for everyone"
  },
  "topic": "all-users"
}'
```

---

## Troubleshooting

### Issue: "Notification not received"

**Check List:**
1. [ ] Is app running? (Check logs)
2. [ ] Do you see FCM token in logs?
3. [ ] Did you grant notification permission?
   - Android: Settings → App → Notifications (ON)
   - iOS: Settings → Notifications (Allow)
4. [ ] Is device connected to internet?
5. [ ] Is Firebase Console working? (Try test message)

**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -v
```

### Issue: "Notification received but role filtering not working"

**Solution:**
1. Check user.role is set correctly
2. Verify Alert.targetRoles field
3. Check app.dart banner display logic
4. View logs for: `"isForRole: true/false"`

### Issue: "Permission denied"

**Solution:**
- **Android:** Grant POST_NOTIFICATIONS in app settings
- **iOS:** Grant notification permission when prompted

---

## Success Criteria

You've successfully implemented FCM when:

✅ **Step 1:** App runs without errors
✅ **Step 2:** FCM token appears in logs
✅ **Step 3:** Test notification received
✅ **Step 4:** Role-based filtering works
✅ **Step 5:** Topic-based messages received

---

## File Structure

```
RescueTN-Mobile-App/
├── lib/
│   ├── models/
│   │   └── alert_model.dart          (✅ Enhanced)
│   ├── core/
│   │   └── services/
│   │       ├── notification_service.dart  (✅ NEW - FCM)
│   │       └── database_service.dart      (✅ Enhanced)
│   ├── features/
│   │   └── 7_alerts/
│   │       └── providers/
│   │           └── alert_notification_provider.dart  (✅ NEW)
│   ├── app/
│   │   └── app.dart                 (✅ Enhanced)
│   └── main.dart                    (✅ Enhanced)
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      (✅ Updated)
└── ios/
    └── Runner/
        └── Info.plist               (✅ Updated)
```

---

## API Reference - Quick

### Listen to Alerts
```dart
final alerts = ref.watch(userAlertsProvider);
```

### Get Unread Count
```dart
final count = ref.watch(unreadAlertsCountProvider);
```

### Mark as Read
```dart
ref.read(alertNotificationProvider.notifier).markAlertAsRead(alertId);
```

### Get FCM Token
```dart
final token = ref.watch(currentFcmTokenProvider);
```

---

## Next Steps

1. ✅ **Test notification reception** (Using Firebase Console)
2. ✅ **Test role-based filtering** (Create users with different roles)
3. ✅ **Monitor delivery** (Firebase Console → Messaging → Analytics)
4. ⏳ **Integrate with dashboard** (Admin can send alerts)
5. ⏳ **Deploy to production** (App Store/Play Store)

---

## Support

- Full documentation: `FCM_NOTIFICATION_GUIDE.md`
- Implementation details: `FCM_IMPLEMENTATION_SUMMARY.md`
- Verification checklist: `FCM_CHECKLIST.md`
- Firebase docs: https://firebase.flutter.dev/docs/messaging

---

## 🎉 You're Ready!

Your RescueTN app now has a production-ready notification system!

**Next:** Run the app and send a test notification! 🚀

