# 📊 Firestore Database Structure & Sample Data

This guide shows exactly how to structure your Firestore database and provides sample JSON data you can import.

---

## 📁 Collections Overview

Your Firestore should have these collections:

```
rescuetn/
├── users/                    # User profiles
├── incidents/               # Disaster reports
├── tasks/                   # Work assignments
├── person_statuses/         # Missing/found persons
├── alerts/                  # Disaster alerts
├── shelters/                # Relief shelters
└── users/{userId}/preparedness_plan/  # User's checklist (subcollection)
```

---

## 👤 Users Collection

**Path**: `/users/{uid}`

**Sample Document**:
```json
{
  "uid": "firebase_user_id_123",
  "email": "volunteer@rescuetn.com",
  "role": "volunteer",
  "skills": ["rescue", "first-aid", "communication"],
  "status": "available"
}
```

**Fields**:
- `uid` (string, required): Firebase Auth UID
- `email` (string, required): User email
- `role` (string, required): "public" or "volunteer"
- `skills` (array of strings, optional): Skills for volunteers
- `status` (string, optional): "available", "busy", or "offline"

**Sample Data to Add**:
```json
// Document ID: user_volunteer_001
{
  "uid": "volunteer_001",
  "email": "ravi.kumar@rescuetn.com",
  "role": "volunteer",
  "skills": ["rescue", "first-aid", "swimming"],
  "status": "available"
}

// Document ID: user_public_001
{
  "uid": "public_001",
  "email": "citizen@rescuetn.com",
  "role": "public",
  "skills": null,
  "status": "available"
}
```

---

## 🚨 Incidents Collection

**Path**: `/incidents/{auto-generated}`

**Sample Document**:
```json
{
  "type": "flood",
  "description": "Heavy flooding in downtown area near bus stand",
  "severity": "high",
  "location": {
    "latitude": 11.0081,
    "longitude": 76.8661
  },
  "reportedBy": "volunteer_001",
  "timestamp": "2024-12-03T10:30:00Z",
  "imageUrls": [
    "gs://rescuetn.appspot.com/incidents/img_123.jpg"
  ],
  "audioUrls": [
    "gs://rescuetn.appspot.com/incidents/audio_123.m4a"
  ],
  "isVerified": false
}
```

**Fields**:
- `type` (string): "flood", "fire", "earthquake", "accident", "medical", "other"
- `description` (string): Detailed description
- `severity` (string): "low", "medium", "high", "critical"
- `location` (GeoPoint): Must be `new GeoPoint(latitude, longitude)`
- `reportedBy` (string): UID of reporter
- `timestamp` (Timestamp): Use server timestamp
- `imageUrls` (array of strings): Storage URLs
- `audioUrls` (array of strings): Storage URLs
- `isVerified` (boolean): Admin verification status

**Sample Data**:
```json
// Add multiple incidents
{
  "type": "flood",
  "description": "Severe flooding at Lakshmi Nagar locality",
  "severity": "critical",
  "location": {"latitude": 11.0081, "longitude": 76.8661},
  "reportedBy": "volunteer_001",
  "timestamp": "2024-12-03T10:30:00Z",
  "imageUrls": [],
  "audioUrls": [],
  "isVerified": true
}

{
  "type": "fire",
  "description": "Building fire at commercial complex",
  "severity": "high",
  "location": {"latitude": 11.0082, "longitude": 76.8662},
  "reportedBy": "public_001",
  "timestamp": "2024-12-03T11:15:00Z",
  "imageUrls": [],
  "audioUrls": [],
  "isVerified": false
}

{
  "type": "accident",
  "description": "Major road accident on bypass road",
  "severity": "high",
  "location": {"latitude": 11.0080, "longitude": 76.8660},
  "reportedBy": "volunteer_002",
  "timestamp": "2024-12-03T12:00:00Z",
  "imageUrls": [],
  "audioUrls": [],
  "isVerified": true
}
```

---

## 📋 Tasks Collection

**Path**: `/tasks/{auto-generated}`

**Sample Document**:
```json
{
  "title": "Distribute water bottles to evacuees",
  "incidentId": "incident_doc_id_here",
  "description": "Provide water bottles to 100+ people at the relief camp",
  "severity": "high",
  "status": "inProgress"
}
```

**Fields**:
- `title` (string): Task name
- `incidentId` (string): Related incident ID
- `description` (string): Detailed task description
- `severity` (string): "low", "medium", "high", "critical"
- `status` (string): "pending", "accepted", "inProgress", "completed"

**Sample Data**:
```json
{
  "title": "Setup medical camp",
  "incidentId": "incident_001",
  "description": "Establish first-aid medical camp at community center",
  "severity": "critical",
  "status": "inProgress"
}

{
  "title": "Search for missing persons",
  "incidentId": "incident_001",
  "description": "Coordinate search teams for 5 missing persons",
  "severity": "critical",
  "status": "pending"
}

{
  "title": "Provide shelter",
  "incidentId": "incident_001",
  "description": "Accommodate 50 evacuees at local school",
  "severity": "high",
  "status": "completed"
}
```

---

## 👥 Person Statuses Collection

**Path**: `/person_statuses/{auto-generated}`

**Sample Document**:
```json
{
  "name": "Raj Kumar",
  "age": 35,
  "status": "missing",
  "lastKnownLocation": "Lakshmi Nagar, Coimbatore",
  "submittedBy": "volunteer_001",
  "timestamp": "2024-12-03T10:30:00Z"
}
```

**Fields**:
- `name` (string): Person's name
- `age` (number): Age
- `status` (string): "safe" or "missing"
- `lastKnownLocation` (string): Location description
- `submittedBy` (string): Submitter's UID
- `timestamp` (Timestamp): When submitted

**Sample Data**:
```json
{
  "name": "Priya Sharma",
  "age": 28,
  "status": "missing",
  "lastKnownLocation": "Market area near bus stand",
  "submittedBy": "public_001",
  "timestamp": "2024-12-03T10:30:00Z"
}

{
  "name": "Arjun Singh",
  "age": 45,
  "status": "safe",
  "lastKnownLocation": "Relief center, Lakshmi Nagar",
  "submittedBy": "volunteer_001",
  "timestamp": "2024-12-03T11:45:00Z"
}
```

---

## 🚨 Alerts Collection

**Path**: `/alerts/{auto-generated}`

**Sample Document**:
```json
{
  "title": "Severe Weather Alert",
  "message": "Heavy rainfall and strong winds expected in next 6 hours",
  "level": "warning",
  "timestamp": "2024-12-03T09:00:00Z"
}
```

**Fields**:
- `title` (string): Alert title
- `message` (string): Alert message
- `level` (string): "info", "warning", "severe"
- `timestamp` (Timestamp): When alert was issued

**Sample Data**:
```json
{
  "title": "Heavy Rain Warning",
  "message": "Meteorological department warns of continuous heavy rainfall",
  "level": "warning",
  "timestamp": "2024-12-03T09:00:00Z"
}

{
  "title": "Flood Alert",
  "message": "Rivers overflowing, evacuate low-lying areas immediately",
  "level": "severe",
  "timestamp": "2024-12-03T10:15:00Z"
}

{
  "title": "Relief Camp Opened",
  "message": "Relief camp opened at Community Center. Find shelter and supplies here.",
  "level": "info",
  "timestamp": "2024-12-03T11:00:00Z"
}
```

---

## 🏚️ Shelters Collection

**Path**: `/shelters/{auto-generated}`

**Sample Document**:
```json
{
  "name": "Government School - Relief Center",
  "location": {
    "latitude": 11.0100,
    "longitude": 76.8700
  },
  "capacity": 500,
  "currentOccupancy": 280,
  "status": "available"
}
```

**Fields**:
- `name` (string): Shelter name
- `location` (GeoPoint): GeoPoint(latitude, longitude)
- `capacity` (number): Total capacity
- `currentOccupancy` (number): Current people
- `status` (string): "available", "full", "closed"

**Sample Data**:
```json
{
  "name": "Government School Annex",
  "location": {"latitude": 11.0085, "longitude": 76.8665},
  "capacity": 500,
  "currentOccupancy": 285,
  "status": "available"
}

{
  "name": "Community Center Main",
  "location": {"latitude": 11.0090, "longitude": 76.8670},
  "capacity": 800,
  "currentOccupancy": 750,
  "status": "full"
}

{
  "name": "Sports Complex North",
  "location": {"latitude": 11.0075, "longitude": 76.8655},
  "capacity": 300,
  "currentOccupancy": 85,
  "status": "available"
}
```

---

## ✅ Preparedness Plan (Subcollection)

**Path**: `/users/{userId}/preparedness_plan/{itemId}`

**Sample Documents**:
```json
{
  "title": "Emergency Water Supply",
  "description": "Store at least 1 gallon of water per person per day",
  "category": "essentials",
  "isCompleted": true
}

{
  "title": "Non-perishable Food",
  "description": "Stock a 3-day supply of non-perishable food",
  "category": "essentials",
  "isCompleted": false
}

{
  "title": "First-Aid Kit",
  "description": "Ensure your first-aid kit is fully stocked",
  "category": "essentials",
  "isCompleted": true
}

{
  "title": "Secure Important Documents",
  "description": "Keep copies of passports, Aadhaar cards, etc., in a waterproof bag",
  "category": "documents",
  "isCompleted": false
}

{
  "title": "Know Your Evacuation Route",
  "description": "Identify your local evacuation routes and have a plan",
  "category": "actions",
  "isCompleted": true
}
```

**Note**: This is auto-created for each user on first login.

---

## 📥 How to Import Sample Data

### Option 1: Manual Entry (Firebase Console)
1. Go to https://console.firebase.google.com/
2. Select **rescuetn** project
3. Go to **Firestore Database**
4. Click **+ Start collection** → Enter collection name
5. Click **+ Add document** → Paste JSON data

### Option 2: Firebase Emulator (Local Testing)
```bash
# Start emulator
firebase emulators:start --only firestore

# Import seed data (if you have seed script)
firebase emulators:start --import=./seed-data
```

### Option 3: Firestore Data Transfer Tool
```bash
# Export from one database
gcloud firestore export gs://my-bucket/path

# Import to another
gcloud firestore import gs://my-bucket/path
```

---

## 🔒 Important Security Notes

### Before Going Live
1. **Never hardcode test data in production**
2. **Use Firestore Rules** (not test mode forever)
3. **Enable backups** in Firebase Console
4. **Monitor usage** to avoid overspending
5. **Set up quotas** in Firebase Console

### Firestore Rules for Production
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
      
      // Preparedness plan - users can read/write their own
      match /preparedness_plan/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
    
    // Incidents - public read, owner can write
    match /incidents/{document=**} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.reportedBy;
    }
    
    // Tasks - authenticated users only
    match /tasks/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Person statuses
    match /person_statuses/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Alerts - public read, admin only write
    match /alerts/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
    
    // Shelters - public read, admin only write
    match /shelters/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
  }
}
```

---

## 📊 Collection Indexes (if needed)

Firestore may prompt to create indexes for complex queries. Accept them when prompted. You can also create manually:

1. Go to Firebase Console → Firestore → Indexes
2. Click **Create index** → Configure for your queries

Common indexes needed:
- `incidents`: ordered by timestamp DESC
- `person_statuses`: ordered by timestamp DESC  
- `alerts`: ordered by timestamp DESC

---

## ✨ You're All Set!

Copy the sample data above and add to your Firestore collections. Then test your app!

For more details:
- Check `BACKEND_SETUP_GUIDE.md`
- Check `QUICK_START.md`
- See `TROUBLESHOOTING.md` for help
