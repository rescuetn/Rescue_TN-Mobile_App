# 🔧 Firebase Integration Checklist & Troubleshooting

## ✅ Pre-Launch Checklist

### Firebase Project Setup
- [ ] Firebase project created (rescuetn)
- [ ] Android app registered in Firebase
- [ ] google-services.json downloaded to `android/app/`
- [ ] iOS app registered (if building for iOS)
- [ ] GoogleService-Info.plist downloaded (for iOS)

### Firebase Services Enabled
- [ ] **Authentication** - Email/Password provider enabled
- [ ] **Cloud Firestore** - Database created (test/production mode)
- [ ] **Cloud Storage** - Bucket created (for images/audio)
- [ ] **Cloud Messaging** - Setup (optional, for push notifications)

### Firestore Setup
- [ ] Collections created: users, incidents, tasks, person_statuses, alerts, shelters
- [ ] Security rules configured and deployed
- [ ] Test data added (optional but helpful)

### Local Environment
- [ ] Flutter installed: `flutter --version`
- [ ] Android SDK setup (for Android testing)
- [ ] Xcode setup (for iOS testing)
- [ ] `flutter pub get` ran successfully
- [ ] No build errors: `flutter analyze`

### Test Accounts
- [ ] Test volunteer account created in Firebase Auth
- [ ] Test public account created in Firebase Auth
- [ ] User documents created in Firestore for each test account

---

## 🚀 Launch Commands

```bash
# Ensure you're in the project directory
cd /Users/karthickrajav/Rescue_TN-Mobile_App

# Get dependencies
flutter pub get

# Check for errors
flutter analyze

# Run on connected device/emulator
flutter run

# Or specify device
flutter run -d <device_id>

# Build for release (Android)
flutter build apk --release

# Build for release (iOS)
flutter build ios --release
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "Could not find google-services.json"
**Error**: `Caused by: java.io.FileNotFoundException: google-services.json not found at android/app/`

**Solution**:
1. Download `google-services.json` from Firebase Console
   - Project Settings → Your apps → Android app → Download google-services.json
2. Place in `android/app/` directory
3. Run: `flutter clean && flutter pub get && flutter run`

---

### Issue 2: "Could not find AndroidManifest.xml"
**Error**: Build failure with manifest issues

**Solution**:
```bash
# Clean build files
flutter clean

# Remove build artifacts
rm -rf build/
rm -rf android/.gradle/

# Get dependencies fresh
flutter pub get

# Try again
flutter run
```

---

### Issue 3: "MissingPluginException" for Firebase
**Error**: `MissingPluginException: No implementation found for method ...`

**Solution**:
```bash
# Clean everything
flutter clean

# Re-download dependencies
flutter pub get

# Rebuild (this recompiles platform channels)
flutter run --verbose

# Or on iOS specifically
cd ios
rm -rf Pods
rm Podfile.lock
cd ..
flutter run
```

---

### Issue 4: "Authentication State Not Persisting"
**Problem**: User logs out when app restarts

**Solution**: This is expected on initial setup. Add this to your Firestore security rules to allow persistent auth:
```javascript
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId;
}
```

---

### Issue 5: "Location Permission Denied"
**Error**: `LocationPermission.denied` when trying to get location

**Solution**:

**Android** - Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** - Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to report incidents</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs your location for rescue operations</string>
```

Then request permission in app or user grants it in device settings.

---

### Issue 6: "Maps API Key Not Configured"
**Error**: Blank maps or "Google Maps SDK not initialized"

**Solution**:

1. Get API key from Google Cloud Console
2. **Android** - Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

3. **iOS** - Add to `ios/Runner/Info.plist`:
```xml
<key>com.google.ios.maps.API_KEY</key>
<string>YOUR_API_KEY_HERE</string>
```

---

### Issue 7: "Firestore Rules Blocking Access"
**Error**: `PERMISSION_DENIED: Missing or insufficient permissions`

**Solution**: Update your Firestore security rules. Replace the default rules with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // For testing only - allow all (INSECURE!)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Then use proper security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /incidents/{document=**} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.reportedBy;
    }
    match /tasks/{document=**} {
      allow read, write: if request.auth != null;
    }
    match /person_statuses/{document=**} {
      allow read, write: if request.auth != null;
    }
    match /alerts/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /shelters/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /users/{userId}/preparedness_plan/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

### Issue 8: "Sign In Works But User Data Missing"
**Problem**: User logs in but profile data is null

**Solution**: 
1. Check that user document exists in Firestore under `users/{uid}`
2. Ensure document has these fields:
   - `uid`
   - `email`
   - `role` (must be "public" or "volunteer")
   - `skills` (optional array for volunteers)
   - `status` (optional, defaults to "available")

Example user document:
```json
{
  "uid": "user123",
  "email": "test@rescuetn.com",
  "role": "volunteer",
  "skills": ["rescue", "first-aid"],
  "status": "available"
}
```

---

### Issue 9: "Real-time Updates Not Working"
**Problem**: Data doesn't update when changed in Firestore

**Solution**:
1. Verify Firestore database is in "Live" mode (not offline)
2. Check network connection
3. Ensure app has internet permission in manifest
4. Try this test:
```dart
// In your test widget
final testStream = ref.watch(databaseServiceProvider).getIncidentsStream();

testStream.listen((incidents) {
  print('Incidents updated: ${incidents.length}');
});
```

---

### Issue 10: "Build Fails with "Cannot Find Flutter"
**Error**: `flutter: command not found`

**Solution**:
```bash
# Add Flutter to PATH
export PATH="$PATH:$(which flutter)"

# Or add to ~/.zshrc permanently
echo 'export PATH="$PATH:[path-to-flutter-sdk]/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify
flutter --version
```

---

## 🔍 Debugging Tips

### Enable Verbose Logging
```bash
flutter run -v

# This shows detailed logs including Firebase operations
```

### Check Firebase Connection
```dart
// Add to main.dart temporarily
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const ProviderScope(child: RescueTNApp()));
}
```

### Monitor Firestore Writes
```dart
// In a test function
final firestore = FirebaseFirestore.instance;

firestore.collection('test').add({
  'message': 'Hello Firestore',
  'timestamp': DateTime.now(),
}).then((docRef) {
  print('✅ Document written with ID: ${docRef.id}');
}).catchError((error) {
  print('❌ Error writing document: $error');
});
```

### Check Auth State
```dart
final auth = FirebaseAuth.instance;

auth.authStateChanges().listen((user) {
  if (user != null) {
    print('✅ User logged in: ${user.email}');
  } else {
    print('❌ User logged out');
  }
});
```

---

## 📱 Device-Specific Issues

### Android Emulator Issues
```bash
# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch <name>

# If Firebase doesn't work in emulator:
# 1. Use a real device (test on actual phone)
# 2. Or use Firebase Emulator Suite for local testing
firebase emulators:start
```

### iOS Simulator Issues
```bash
# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
cd ..

# Get dependencies
flutter pub get

# Run
flutter run -d "iPhone 15"
```

---

## 🎯 Verification Steps

After fixing any issue, verify with these steps:

1. **Check Build**
   ```bash
   flutter analyze    # Should have 0 errors
   flutter run       # Should launch app
   ```

2. **Test Authentication**
   - Open app
   - Go to login screen
   - Tap "Don't have account?" to register
   - Fill form and sign up
   - Should redirect to home screen
   - Go to Profile to verify user data

3. **Test Database Write**
   - Go to Incident Report screen
   - Fill form and submit
   - Check Firebase Console → Firestore
   - Should see new incident in `incidents` collection

4. **Test Real-time Read**
   - Go to Dashboard or Alerts
   - Open Firestore in another browser
   - Add new alert document
   - App should update automatically

---

## 📞 Getting Help

### Check These First
- [Firebase Flutter Setup](https://firebase.flutter.dev/)
- [Flutter Troubleshooting](https://flutter.dev/docs/testing/troubleshooting)
- [Stack Overflow - tag:flutter-firebase](https://stackoverflow.com/questions/tagged/flutter%20firebase)

### Document Your Issue
When asking for help, provide:
1. Full error message
2. Steps to reproduce
3. `flutter doctor -v` output
4. `flutter analyze` output
5. Platform (Android/iOS)

---

## ✨ You're Ready!

Most issues are resolved by:
1. `flutter clean`
2. `flutter pub get`
3. `flutter run`

If problems persist, check this guide or provide details above when asking for help.

Good luck! 🚀
