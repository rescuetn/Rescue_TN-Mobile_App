import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/incident_model.dart';

// Provider for Firebase Storage instance
final firebaseStorageProvider =
Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

/// Abstract class (contract) for the incident repository.
abstract class IncidentRepository {
  Future<void> submitIncident({
    required Incident incident,
    required List<File> images,
    required List<String> audioPaths,
    required Function(String, double) onProgress,
  });

  /// Get a stream of all incidents from Firestore
  Stream<List<Incident>> getIncidentsStream();
}

/// Provider for our IncidentRepository.
final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return FirebaseIncidentRepository(ref);
});

/// Stream provider for real-time incidents
final incidentStreamProvider = StreamProvider<List<Incident>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return repository.getIncidentsStream();
});

/// Concrete implementation using Firebase.
class FirebaseIncidentRepository implements IncidentRepository {
  final Ref _ref;
  FirebaseIncidentRepository(this._ref);

  DatabaseService get _databaseService => _ref.read(databaseServiceProvider);
  FirebaseStorage get _storage => _ref.read(firebaseStorageProvider);

  /// Helper to upload a single file and report progress.
  Future<String> _uploadFile(
      File file,
      String path,
      Function(double) onProgress,
      ) async {
    final storageRef = _storage.ref().child(path);
    final uploadTask = storageRef.putFile(file);

    // Listen to the upload task's stream to get progress updates.
    uploadTask.snapshotEvents.listen((taskSnapshot) {
      final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
      onProgress(progress);
    });

    // Wait for the upload to complete.
    await uploadTask;
    return await storageRef.getDownloadURL();
  }

  @override
  Future<void> submitIncident({
    required Incident incident,
    required List<File> images,
    required List<String> audioPaths,
    required Function(String, double) onProgress,
  }) async {
    final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
    List<String> imageUrls = [];
    List<String> audioUrls = [];

    // 1. Upload Images
    for (int i = 0; i < images.length; i++) {
      onProgress('Uploading image ${i + 1}/${images.length}...', 0.0);
      final imageUrl = await _uploadFile(
        images[i],
        'incidents/$incidentId/images/image_$i.jpg',
            (progress) => onProgress(
          'Uploading image ${i + 1}/${images.length}...',
          progress,
        ),
      );
      imageUrls.add(imageUrl);
    }

    // 2. Upload Audio
    for (int i = 0; i < audioPaths.length; i++) {
      onProgress('Uploading audio ${i + 1}/${audioPaths.length}...', 0.0);
      final audioUrl = await _uploadFile(
        File(audioPaths[i]),
        'incidents/$incidentId/audio/recording_$i.m4a',
            (progress) => onProgress(
          'Uploading audio ${i + 1}/${audioPaths.length}...',
          progress,
        ),
      );
      audioUrls.add(audioUrl);
    }

    // 3. Create the final Incident object with all media URLs.
    final incidentWithMedia = incident.copyWith(
      imageUrls: imageUrls,
      audioUrls: audioUrls,
    );

    // 4. Save the complete incident data to Firestore.
    onProgress('Finalizing report...', 1.0);
    await _databaseService.addIncident(incidentWithMedia);
  }

  @override
  Stream<List<Incident>> getIncidentsStream() {
    // Delegate to the database service to get the stream of incidents
    return _databaseService.getIncidentsStream();
  }
}