import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/models/alert_model.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:rescuetn/models/person_status_model.dart';
import 'package:rescuetn/models/preparedness_model.dart';
import 'package:rescuetn/models/shelter_model.dart';
import 'package:rescuetn/models/task_model.dart';
import 'package:rescuetn/models/user_model.dart';

/// Provides a singleton instance of [FirebaseFirestore].
final firestoreProvider =
Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// An abstract class defining the contract for all database operations.
abstract class DatabaseService {
  // User operations
  Future<void> createUserRecord(AppUser user);
  Future<void> updateUserRecord(AppUser user);
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

  // Preparedness Plan operations
  Future<void> checkAndCreateDefaultPlan(String userId);
  Stream<List<PreparednessItem>> getPreparednessPlanStream(String userId);
  Future<void> updatePreparednessItemStatus(
      String userId, String itemId, bool newStatus);

  // Shelter operations
  Stream<List<Shelter>> getSheltersStream();

  // Alert operations
  Stream<List<Alert>> getAlertsStream();
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
  Future<void> updateUserRecord(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
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
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Incident.fromMap(doc.data(), doc.id))
        .toList());
  }

  // --- TASK METHODS ---
  @override
  Stream<List<Task>> getTasksStream() {
    return _firestore.collection('tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList());
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
        .map((snapshot) => snapshot.docs
        .map((doc) => PersonStatus.fromMap(doc.data(), doc.id))
        .toList());
  }

  // --- PREPAREDNESS PLAN METHODS ---
  @override
  Future<void> checkAndCreateDefaultPlan(String userId) async {
    final planCollection =
    _firestore.collection('users').doc(userId).collection('preparedness_plan');
    final snapshot = await planCollection.limit(1).get();

    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      for (final item in _defaultPlan) {
        final docRef = planCollection.doc(item.id);
        batch.set(docRef, item.toMap());
      }
      await batch.commit();
    }
  }

  @override
  Stream<List<PreparednessItem>> getPreparednessPlanStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preparedness_plan')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PreparednessItem.fromMap(doc.data(), doc.id))
        .toList());
  }

  @override
  Future<void> updatePreparednessItemStatus(
      String userId, String itemId, bool newStatus) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preparedness_plan')
        .doc(itemId)
        .update({'isCompleted': newStatus});
  }

  // --- SHELTER METHOD ---
  @override
  Stream<List<Shelter>> getSheltersStream() {
    return _firestore.collection('shelters').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Shelter.fromMap(doc.data(), doc.id)).toList());
  }

  // --- ALERTS METHOD ---
  @override
  Stream<List<Alert>> getAlertsStream() {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Alert.fromMap(doc.data(), doc.id)).toList());
  }
}

// Helper list containing the default preparedness items for new users.
const List<PreparednessItem> _defaultPlan = [
  PreparednessItem(
      id: 'p-01',
      title: 'Emergency Water Supply',
      description: 'Store at least 1 gallon of water per person per day.',
      category: PreparednessCategory.essentials),
  PreparednessItem(
      id: 'p-02',
      title: 'Non-perishable Food',
      description: 'Stock a 3-day supply of non-perishable food.',
      category: PreparednessCategory.essentials),
  PreparednessItem(
      id: 'p-03',
      title: 'First-Aid Kit',
      description: 'Ensure your first-aid kit is fully stocked.',
      category: PreparednessCategory.essentials),
  PreparednessItem(
      id: 'p-04',
      title: 'Secure Important Documents',
      description:
      'Keep copies of passports, Aadhaar cards, etc., in a waterproof bag.',
      category: PreparednessCategory.documents),
  PreparednessItem(
      id: 'p-05',
      title: 'Know Your Evacuation Route',
      description: 'Identify your local evacuation routes and have a plan.',
      category: PreparednessCategory.actions),
];