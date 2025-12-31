# RescueTN - Disaster Management Mobile App

A comprehensive Flutter mobile application for disaster management and emergency response in Tamil Nadu.

## 🚀 Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the app
flutter run

# 3. Check logs for FCM token
# Look for: "FCM Token: ..."

# 4. Send test notification
# Firebase Console → Messaging → Send test message
```

## 📋 Project Overview

**RescueTN** is a production-ready Flutter application with:

- ✅ Firebase Authentication (Email/Password)
- ✅ Firestore Database with real-time updates
- ✅ Firebase Cloud Messaging (FCM) notifications
- ✅ Role-based alert delivery system
- ✅ Incident reporting with location & media
- ✅ Task management system
- ✅ Preparedness planning
- ✅ Shelter information & mapping
- ✅ Real-time data synchronization

## 📁 Project Structure

```
lib/
├── features/
│   ├── 1_auth/              # Authentication
│   ├── 2_dashboard/         # Home dashboard
│   ├── 3_incident_reporting/# Incident reporting
│   ├── 4_tasks/             # Task management
│   ├── 5_person_status/     # Person status tracking
│   ├── 6_preparedness/      # Preparedness planning
│   ├── 7_alerts/            # Alert system & FCM
│   ├── 8_shelters/          # Shelter information
│   └── 9_map/               # Map integration
├── services/                # Firebase services
├── models/                  # Data models
└── providers/               # Riverpod providers
```

## 🔧 Setup Requirements

1. **Firebase Project**: Create a project at [Firebase Console](https://console.firebase.google.com/)
2. **google-services.json**: Place at `android/app/google-services.json`
3. **GoogleService-Info.plist**: Place at `ios/Runner/GoogleService-Info.plist`
4. **Enable Services**:
   - Authentication (Email/Password)
   - Firestore Database
   - Cloud Storage
   - Cloud Messaging (FCM)

## 📚 Documentation

For detailed setup and usage instructions, see **📖_START_HERE.txt**

## 🧪 Testing

- Test registration with any email/password
- Report incidents with location and media
- Send FCM test notifications via Firebase Console
- Monitor real-time data updates in Firestore

## 🔐 Security

- Firestore security rules configured for role-based access
- User authentication required for all features
- Data validation on client and server side

## 📦 Dependencies

- **flutter_riverpod**: State management
- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **cloud_firestore**: Database
- **firebase_messaging**: Push notifications
- **google_maps_flutter**: Maps integration
- **image_picker**: Image selection
- **geolocator**: Location services

## 🚀 Deployment

1. Update version in `pubspec.yaml`
2. Run `flutter build apk` (Android) or `flutter build ios` (iOS)
3. Upload to Google Play Store or Apple App Store

## 🎥 Project Demo Video

**▶️ Watch the RescueTN working demo here:
https://www.instagram.com/reel/DSmkQpiETy7/?igsh=MTZnaWljZ2NmcG1zMQ==

## 📞 Support

For issues and troubleshooting, refer to **📖_START_HERE.txt** for comprehensive guides and solutions.

## 📄 License

This project is proprietary software for RescueTN.
