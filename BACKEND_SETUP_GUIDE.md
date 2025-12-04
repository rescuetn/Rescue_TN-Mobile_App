# RescueTN Mobile App - Backend & Firebase Integration Guide

## 🎯 Project Overview

Your **RescueTN** Flutter app is a disaster management and rescue coordination application. It has a **well-designed UI** with **proper Firebase backend integration already in place**. You don't need to rebuild from scratch — just verify and run it!

---

## ✅ What You Already Have

### 1. **Firebase Configuration** ✓
- ✅ `google-services.json` configured in `android/app/`
- ✅ Firebase Project ID: `rescuetn`
- ✅ Firebase API Key configured
- ✅ All Firebase services enabled

### 2. **Authentication Service** ✓
- **File**: `lib/core/services/auth_service.dart` (Abstract)
- **Implementation**: `lib/features/1_auth/repository/auth_repository.dart`
- **Features**:
  - Email/Password authentication
  - User roles (Public, Volunteer)
  - Volunteer skills support
  - Password reset
  - Sign in/Sign up with Firestore integration

### 3. **Database Service** ✓
- **File**: `lib/core/services/database_service.dart` (Abstract)
- **Implementation**: `lib/core/services/database_service.dart` (FirestoreDatabaseService)
- **Features**:
  - User management
  - Incident tracking with location & media
  - Task management
  - Person status registry
  - Preparedness planning
  - Shelter locator
  - Real-time alerts

### 4. **Data Models** ✓
All models have proper serialization:
- `user_model.dart` - User data with roles and skills
- `incident_model.dart` - Incident reports with severity
- `task_model.dart` - Task management
- `person_status_model.dart` - Person registry
- `alert_model.dart` - Alert notifications
- `shelter_model.dart` - Shelter information
- `preparedness_model.dart` - Preparedness checklist

### 5. **State Management** ✓
- **Provider**: `flutter_riverpod` (2.5.1)
- **Auth Providers**: 
  - `authStateChangesProvider` - Watches authentication state
  - `authRepositoryProvider` - Firebase Auth service
  - `isAuthenticatedProvider` - Authentication check
  - `currentUserProvider` - Current user data

### 6. **Navigation** ✓
- **Router**: `lib/app/router.dart`
- **Package**: `go_router` (14.2.0)
- Routes for all features (Auth, Dashboard, Incidents, Tasks, etc.)

### 7. **Services** ✓
- **Location Service**: Uses `geolocator` for real-time location
- **Notification Service**: Firebase Messaging configured
- **Image/Audio**: Image picker and audio recording support

---

## 📋 Firestore Database Structure

Based on your implementation, your Firestore should have:

```
firestore
├── users/
│   ├── {uid}/
│   │   ├── uid
│   │   ├── email
│   │   ├── role (public | volunteer)
│   │   ├── skills[] (for volunteers)
│   │   └── status (available | busy | offline)
│
├── incidents/
│   ├── {id}/
│   │   ├── type (flood | fire | earthquake | accident | medical | other)
│   │   ├── description
│   │   ├── severity (low | medium | high | critical)
│   │   ├── location (GeoPoint)
│   │   ├── reportedBy
│   │   ├── timestamp
│   │   ├── imageUrls[]
│   │   ├── audioUrls[]
│   │   └── isVerified
│
├── tasks/
│   ├── {id}/
│   │   ├── title
│   │   ├── incidentId
│   │   ├── description
│   │   ├── severity
│   │   └── status (pending | accepted | inProgress | completed)
│
├── person_statuses/
│   ├── {id}/
│   │   ├── personName
│   │   ├── status
│   │   ├── location
│   │   └── timestamp
│
├── shelters/
│   ├── {id}/
│   │   ├── name
│   │   ├── location
│   │   ├── capacity
│   │   └── available
│
├── alerts/
│   ├── {id}/
│   │   ├── title
│   │   ├── message
│   │   ├── severity
│   │   ├── timestamp
│   │   └── read
│
└── users/{uid}/preparedness_plan/
    ├── {id}/
    │   ├── title
    │   ├── description
    │   ├── category
    │   └── isCompleted
```

---

## 🚀 How to Get Your App Running

### Step 1: Set Up Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project **rescuetn**
3. Enable these services:
   - ✅ **Authentication** (Email/Password)
   - ✅ **Cloud Firestore** (Database)
   - ✅ **Storage** (for images/audio)
   - ✅ **Cloud Messaging** (for notifications)

### Step 2: Set Firestore Rules (Security)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Everyone can read incidents
    match /incidents/{document=**} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.reportedBy;
    }
    
    // Similar rules for other collections...
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 3: Run Flutter App
```bash
cd /Users/karthickrajav/Rescue_TN-Mobile_App

# Get dependencies
flutter pub get

# Run on Android/iOS
flutter run
```

---

## 🔧 What Still Needs Setup

### 1. **Create Test Users in Firebase**
In Firebase Console → Authentication → Add user:
- Email: `volunteer@rescuetn.com` / Password: `test123`
- Email: `public@rescuetn.com` / Password: `test123`

### 2. **Sample Data in Firestore**
You can manually add test data or create a data seeding script.

### 3. **Firebase Emulator (Optional - for local testing)**
```bash
firebase emulators:start
```

---

## 📦 Dependencies Summary

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | 2.32.0 | Firebase initialization |
| firebase_auth | 4.20.0 | Authentication |
| cloud_firestore | 4.17.4 | Database |
| firebase_storage | 11.7.5 | File storage |
| firebase_messaging | 14.9.3 | Push notifications |
| flutter_riverpod | 2.5.1 | State management |
| go_router | 14.2.0 | Navigation |
| geolocator | 12.0.0 | Location services |
| google_maps_flutter | 2.7.0 | Maps |

---

## 🎨 App Features (Already Built)

1. **Authentication** - Register & Login with roles
2. **Dashboard** - Volunteer & Public dashboards
3. **Incident Reporting** - Report with location, images, audio
4. **Task Management** - Accept and track tasks
5. **Shelter Locator** - Find shelters on map
6. **Person Registry** - Track missing/found persons
7. **Alerts** - Real-time disaster alerts
8. **Preparedness Plan** - Personal disaster prep checklist
9. **Heatmap** - Visualize incident locations

---

## ⚠️ Minor Issues to Fix (Optional)

### 1. Deprecated Color Methods
Many files use `.withOpacity()` which is deprecated. Replace with `.withValues()`:
```dart
// Old
Colors.red.withOpacity(0.5)

// New
Colors.red.withValues(alpha: 0.5)
```

### 2. Asset Missing
Add `assets/translations/` directory or remove from `pubspec.yaml` if not needed.

---

## 📝 Next Steps

1. ✅ **Create Firebase project** (already done - rescuetn)
2. ✅ **Enable services** in Firebase Console
3. ✅ **Set Firestore rules** for security
4. ✅ **Create test users** in Firebase Auth
5. ✅ **Run the app**: `flutter run`
6. ✅ **Test login** with your Firebase users
7. ✅ **Add test data** to Firestore
8. ✅ **Test features** (report incident, task management, etc.)

---

## 🔗 Useful Resources

- [Firebase Documentation](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

---

## ✨ Summary

Your app **already has a complete backend implementation** using Firebase! You just need to:
1. Set up your Firebase Console properly
2. Add test data
3. Run the app

The UI, services, providers, and models are all already implemented and connected. You're ready to launch! 🚀
