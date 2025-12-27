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
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {
    String? completionImageUrl,
    String? completionAudioUrl,
    String? completionNotes,
    bool? needsMoreVolunteers,
    int? additionalVolunteersNeeded,
    String? challengesFaced,
  });

  // Person Status operations
  Future<void> addPersonStatus(PersonStatus personStatus);
  Stream<List<PersonStatus>> getPersonStatusStream();



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
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {
    String? completionImageUrl,
    String? completionAudioUrl,
    String? completionNotes,
    bool? needsMoreVolunteers,
    int? additionalVolunteersNeeded,
    String? challengesFaced,
  }) async {
    final Map<String, dynamic> updates = {
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newStatus == TaskStatus.completed) {
      if (completionImageUrl != null) {
        updates['completionImageUrl'] = completionImageUrl;
      }
      if (completionAudioUrl != null) {
        updates['completionAudioUrl'] = completionAudioUrl;
      }
      if (completionNotes != null) {
        updates['completionNotes'] = completionNotes;
      }
      if (needsMoreVolunteers != null) {
        updates['needsMoreVolunteers'] = needsMoreVolunteers;
      }
      if (additionalVolunteersNeeded != null) {
        updates['additionalVolunteersNeeded'] = additionalVolunteersNeeded;
      }
      if (challengesFaced != null) {
        updates['challengesFaced'] = challengesFaced;
      }
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


