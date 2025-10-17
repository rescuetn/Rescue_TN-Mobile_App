import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:rescuetn/models/person_status_model.dart';
import 'package:rescuetn/models/task_model.dart';
import 'package:rescuetn/models/user_model.dart';

/// Provides a singleton instance of [FirebaseFirestore].
final firestoreProvider =
Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// An abstract class defining the contract for all database operations.
/// This is the single source of truth for what our app can do with its data.
abstract class DatabaseService {
  // User operations
  Future<void> createUserRecord(AppUser user);
  Future<AppUser?> getUserRecord(String uid);

  // Incident operations
  Future<void> addIncident(Incident incident);
  Stream<List<Incident>> getIncidentsStream();

  // Task operations
  Stream<List<Task>> getTasksStream();
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus);

  // Person Status operations
  Future<void> addPersonStatus(PersonStatus personStatus);
  Stream<List<PersonStatus>> getPersonStatusStream();
}

/// Provides a concrete implementation of [DatabaseService] using Firestore.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return FirestoreDatabaseService(ref.watch(firestoreProvider));
});

class FirestoreDatabaseService implements DatabaseService {
  final FirebaseFirestore _firestore;
  FirestoreDatabaseService(this._firestore);

  // --- USER METHODS ---
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

  // --- INCIDENT METHODS ---
  @override
  Future<void> addIncident(Incident incident) async {
    await _firestore.collection('incidents').add(incident.toMap());
  }

  @override
  Stream<List<Incident>> getIncidentsStream() {
    return _firestore
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .limit(20) // Get the 20 most recent incidents
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Incident.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- TASK METHODS ---
  @override
  Stream<List<Task>> getTasksStream() {
    // In a real production app, you would filter this, e.g., .where('assignedTo', isEqualTo: userId)
    return _firestore.collection('tasks').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .update({'status': newStatus.name});
  }

  // --- PERSON STATUS METHODS ---
  @override
  Future<void> addPersonStatus(PersonStatus personStatus) async {
    await _firestore.collection('person_statuses').add(personStatus.toMap());
  }

  @override
  Stream<List<PersonStatus>> getPersonStatusStream() {
    return _firestore
        .collection('person_statuses')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PersonStatus.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}

