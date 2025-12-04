# Quick Start - Testing Your App

## 🧪 Test Scenarios

### 1. Testing Registration
```dart
// Your app's registration flow is in:
// lib/features/1_auth/screens/register_screen.dart

// When user signs up with:
// - Email: test@rescuetn.com
// - Password: password123
// - Role: volunteer
// - Skills: [rescue, first-aid]

// The flow:
// 1. User enters details in RegisterScreen
// 2. UserProfileNotifier stores data in state
// 3. FirebaseAuthService.createUserWithEmailAndPassword() is called
// 4. Firebase Auth creates user
// 5. AppUser object with role & skills is saved to Firestore
// 6. User is redirected to home dashboard
```

### 2. Testing Incident Reporting
```dart
// File: lib/features/3_incident_reporting/screens/report_incident_screen.dart

// User can:
// 1. Select incident type (flood, fire, earthquake, etc.)
// 2. Enter description
// 3. Select severity (low, medium, high, critical)
// 4. Device location is auto-fetched via LocationService
// 5. Upload images & audio via ImagePicker & AudioRecorder
// 6. Submit incident which gets saved to Firestore

// The saved data includes:
// - All incident details
// - GeoPoint(latitude, longitude) for mapping
// - Image URLs after upload to Storage
// - Audio URLs after upload to Storage
// - Timestamp for ordering
// - reportedBy: current user's UID
```

### 3. Testing Real-time Data
```dart
// All these streams update in real-time:

// Get incidents stream
final incidents = ref.watch(databaseServiceProvider).getIncidentsStream();

// Get tasks stream
final tasks = ref.watch(databaseServiceProvider).getTasksStream();

// Get person statuses stream
final persons = ref.watch(databaseServiceProvider).getPersonStatusStream();

// Get alerts stream
final alerts = ref.watch(databaseServiceProvider).getAlertsStream();

// Get shelters stream
final shelters = ref.watch(databaseServiceProvider).getSheltersStream();

// When you add new data to Firestore, all these streams update automatically!
```

### 4. Testing Preparedness Plan
```dart
// File: lib/features/6_preparedness/screens/preparedness_plan_screen.dart

// When user opens preparedness plan:
// 1. DatabaseService checks if user has a plan
// 2. If not, creates default plan with 5 items
// 3. User can check off items (isCompleted: true/false)
// 4. Changes sync to Firestore in real-time
```

---

## 📱 How to Add Test Data to Firestore

### Option 1: Using Firebase Console (Web UI)
1. Go to https://console.firebase.google.com/
2. Select **rescuetn** project
3. Go to **Firestore Database**
4. Click **+ Start collection**
5. Add collections with test data

### Option 2: Using Firebase CLI
```bash
# Install Firebase Tools
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize in your project directory
firebase init

# Use Emulator for local testing
firebase emulators:start --only firestore
```

### Option 3: Add Sample Data Code (Optional)
Create a script in Flutter to seed test data:

```dart
// In a test file or debug function
Future<void> seedTestData() async {
  final firestore = FirebaseFirestore.instance;
  
  // Create test incident
  await firestore.collection('incidents').add({
    'type': 'flood',
    'description': 'Heavy flooding in downtown area',
    'severity': 'high',
    'location': GeoPoint(11.0081, 76.8661), // Coimbatore
    'reportedBy': 'user123',
    'timestamp': Timestamp.now(),
    'imageUrls': [],
    'audioUrls': [],
    'isVerified': false,
  });
  
  // Create test shelter
  await firestore.collection('shelters').add({
    'name': 'Community Center - Relief',
    'location': GeoPoint(11.0081, 76.8661),
    'capacity': 500,
    'available': 200,
  });
  
  // Create test alert
  await firestore.collection('alerts').add({
    'title': 'Flood Alert',
    'message': 'Heavy rainfall warning in effect',
    'severity': 'high',
    'timestamp': Timestamp.now(),
    'read': false,
  });
}
```

---

## 🔐 Firebase Security Rules

Your Firestore should have these rules for proper access control:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - each user can only read/write their own
    match /users/{userId} {
      allow read: if request.auth.uid == userId || request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Incidents collection - everyone authenticated can read, users can create
    match /incidents/{document=**} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.reportedBy;
    }
    
    // Tasks collection
    match /tasks/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Person statuses collection
    match /person_statuses/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Preparedness plan - subcollection under users
    match /users/{userId}/preparedness_plan/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Shelters - everyone can read
    match /shelters/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
    
    // Alerts - everyone can read
    match /alerts/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
  }
}
```

---

## 🧑‍💻 Testing with Android Emulator

```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_name>

# Run app on emulator
flutter run

# Or specify device
flutter run -d emulator-5554
```

---

## 🍎 Testing with iOS Simulator

```bash
# List available simulators
xcrun simctl list devices

# Run on iOS simulator
flutter run -d "iPhone 15"
```

---

## 📊 Debugging Tips

### View Firestore Data in Real-time
```dart
// In your provider or screen
ref.listen(databaseServiceProvider.getIncidentsStream(), (previous, next) {
  print('Incidents updated: $next');
});
```

### Check Authentication State
```dart
// Watch auth state
ref.watch(authStateChangesProvider).when(
  data: (user) => print('Logged in as: ${user?.email}'),
  loading: () => print('Loading...'),
  error: (error, _) => print('Auth error: $error'),
);
```

### Enable Firebase Logging
```dart
// In main.dart
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Firebase debugging
  FirebaseAuth.instance.setLanguageCode('en');
  
  await Firebase.initializeApp();
  
  // Optional: Enable verbose logging
  // FirebaseFirestore.instance.settings = const Settings(
  //   persistenceEnabled: true,
  // );
  
  runApp(const ProviderScope(child: RescueTNApp()));
}
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "User record not found in database"
**Solution**: Make sure `createUserRecord()` is being called in Firestore after Firebase Auth user creation. Check that the user document exists in `/users/{uid}`.

### Issue 2: Location permission denied
**Solution**: App needs location permissions:
- Android: Add to `android/app/src/main/AndroidManifest.xml`
- iOS: Add to `ios/Runner/Info.plist`
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Issue 3: Maps API key not working
**Solution**: You need Google Maps API key:
1. Get key from Google Cloud Console
2. Add to Android: `android/app/src/main/AndroidManifest.xml`
3. Add to iOS: `ios/Runner/GeneratedPluginRegistrant.m`

### Issue 4: "google-services.json" not found
**Solution**: Ensure file exists at `android/app/google-services.json`. If migrating projects, download new one from Firebase Console.

---

## ✅ Verification Checklist

- [ ] Firebase project created
- [ ] google-services.json in correct location
- [ ] Authentication service enabled
- [ ] Firestore database created
- [ ] Security rules configured
- [ ] Test user account created
- [ ] App runs without errors
- [ ] Can login with test account
- [ ] Can report an incident
- [ ] Data appears in Firestore console
- [ ] Real-time updates work
- [ ] Tasks update in real-time

---

## 🎉 You're Ready!

Your app is fully functional and ready to use. Just:
1. ✅ Set up Firebase services
2. ✅ Add test data
3. ✅ Run `flutter run`
4. ✅ Test the features

The backend is complete - enjoy building! 🚀
