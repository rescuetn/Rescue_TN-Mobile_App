import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:rescuetn/models/user_model.dart';

final firestoreProvider =
Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// An abstract class defining the contract for database operations.
abstract class DatabaseService {
  Future<void> createUserRecord(AppUser user);
  Future<AppUser?> getUserRecord(String uid);
  // --- ADD THIS METHOD to the contract ---
  Future<void> addIncident(Incident incident);
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return FirestoreDatabaseService(ref.watch(firestoreProvider));
});

/// The concrete implementation of our DatabaseService using Firestore.
class FirestoreDatabaseService implements DatabaseService {
  final FirebaseFirestore _firestore;
  FirestoreDatabaseService(this._firestore);

  @override
  Future<void> createUserRecord(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  @override
  Future<AppUser?> getUserRecord(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  // --- ADD THIS IMPLEMENTATION ---
  @override
  Future<void> addIncident(Incident incident) async {
    // Adds a new document to the 'incidents' collection.
    // Firestore will automatically generate a unique ID.
    await _firestore.collection('incidents').add(incident.toMap());
  }
}