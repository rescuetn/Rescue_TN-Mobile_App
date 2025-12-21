import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  Stream<AppUser?> getUserStream(String uid);

  // Incident operations
  Future<void> addIncident(Incident incident);
  Stream<List<Incident>> getIncidentsStream();

  // Task operations
  Stream<List<Task>> getTasksStream();
  Future<Task?> getTask(String taskId);
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {String? completionImageUrl});

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
  Future<void> addAlert(Alert alert);
  Future<void> updateAlertStatus(String alertId, bool isRead);
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

  @override
  Stream<AppUser?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .transform(StreamTransformer.fromHandlers(
          handleData: (doc, sink) {
            if (doc.exists && doc.data() != null) {
              sink.add(AppUser.fromMap(doc.data()!));
            } else {
              sink.add(null);
            }
          },
          handleError: (error, stackTrace, sink) {
             // Suppress permission errors specifically during logout transitions
             if (error.toString().contains('permission-denied')) {
               sink.add(null);
             } else {
               sink.addError(error, stackTrace);
             }
          },
        ));
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
        .transform(StreamTransformer.fromHandlers(
          handleData: (snapshot, sink) {
            sink.add(snapshot.docs
                .map((doc) => Incident.fromMap(doc.data(), doc.id))
                .toList());
          },
          handleError: (error, stackTrace, sink) {
            sink.add(<Incident>[]);
          },
        ));
  }

  // --- TASK METHODS ---
  @override
  Stream<List<Task>> getTasksStream() {
    return _firestore
        .collection('tasks')
        .snapshots()
        .transform(StreamTransformer.fromHandlers(
          handleData: (snapshot, sink) {
            sink.add(snapshot.docs
                .map((doc) {
                  try {
                    return Task.fromMap(doc.data(), doc.id);
                  } catch (e, s) {
                    debugPrint('Error parsing task ${doc.id}: $e');
                    debugPrint(s.toString());
                    return null;
                  }
                })
                .whereType<Task>()
                .toList());
          },
          handleError: (error, stackTrace, sink) {
            debugPrint('Error getting tasks stream: $error');
            sink.add(<Task>[]);
          },
        ));
  }

  @override
  Future<Task?> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      if (doc.exists && doc.data() != null) {
        return Task.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e, s) {
      debugPrint('Error fetching task $taskId: $e');
      debugPrint(s.toString());
      return null;
    }
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {String? completionImageUrl}) async {
    final Map<String, dynamic> updates = {
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newStatus == TaskStatus.completed) {
      if (completionImageUrl != null) {
        updates['completionImageUrl'] = completionImageUrl;
      }
      // Set completedAt only if not already set (or always update if you prefer)
      updates['completedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('tasks').doc(taskId).update(updates);
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
  @override
  Future<void> checkAndCreateDefaultPlan(String userId) async {
    try {
      final planCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('preparedness_plan');
      
      // Fetch current plan to check for missing items
      final snapshot = await planCollection.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      
      final batch = _firestore.batch();
      bool updatesNeeded = false;

      for (final item in _defaultPlan) {
        if (!existingIds.contains(item.id)) {
          final docRef = planCollection.doc(item.id);
          batch.set(docRef, item.toMap());
          updatesNeeded = true;
        }
      }

      if (updatesNeeded) {
        await batch.commit();
      }
    } catch (e) {
      // Silently fail or log to crashlytics in production
      rethrow;
    }
  }

  @override
  Stream<List<PreparednessItem>> getPreparednessPlanStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preparedness_plan')
        .snapshots()
        .transform(StreamTransformer.fromHandlers(
          handleData: (snapshot, sink) {
            try {
              sink.add(snapshot.docs
                  .map((doc) => PreparednessItem.fromMap(doc.data(), doc.id))
                  .toList());
            } catch (e) {
              sink.add(<PreparednessItem>[]);
            }
          },
          handleError: (error, stackTrace, sink) {
            sink.add(<PreparednessItem>[]);
          },
        ));
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
    return _firestore
        .collection('shelters')
        .snapshots()
        .transform(StreamTransformer.fromHandlers(
          handleData: (snapshot, sink) {
            sink.add(snapshot.docs
                .map((doc) => Shelter.fromMap(doc.data(), doc.id))
                .toList());
          },
          handleError: (error, stackTrace, sink) {
            sink.add(<Shelter>[]);
          },
        ));
  }

  // --- ALERTS METHODS ---
  @override
  Stream<List<Alert>> getAlertsStream() {
    return _firestore
        .collection('emergency_alerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .transform(StreamTransformer.fromHandlers(
          handleData: (snapshot, sink) {
            sink.add(snapshot.docs
                .map((doc) {
                  try {
                    return Alert.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    return Alert(
                      id: doc.id,
                      title: 'Error loading alert',
                      message: 'Could not parse alert data',
                      level: AlertLevel.info,
                      timestamp: DateTime.now(),
                    );
                  }
                })
                .toList());
          },
          handleError: (error, stackTrace, sink) {
            sink.add(<Alert>[]);
          },
        ));
  }

  @override
  Future<void> addAlert(Alert alert) async {
    await _firestore.collection('emergency_alerts').add({
      'title': alert.title,
      'message': alert.message,
      'level': alert.level.name,
      'timestamp': Timestamp.fromDate(alert.timestamp),
      'targetRoles': alert.targetRoles,
      'imageUrl': alert.imageUrl,
      'isRead': alert.isRead,
      'actionUrl': alert.actionUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateAlertStatus(String alertId, bool isRead) async {
    await _firestore
        .collection('emergency_alerts')
        .doc(alertId)
        .update({'isRead': isRead});
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
