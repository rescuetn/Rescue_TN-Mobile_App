import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  /// Uploads a task completion image to Firebase Storage.
  /// Returns the download URL of the uploaded image.
  Future<String> uploadTaskCompletionImage(String taskId, File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = _storage.ref().child('task_completion_proofs/$taskId/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads a task completion audio to Firebase Storage.
  /// Returns the download URL of the uploaded audio.
  Future<String> uploadTaskCompletionAudio(String taskId, File audioFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      final ref = _storage.ref().child('task_completion_proofs/$taskId/audio_$fileName');
      
      final uploadTask = ref.putFile(audioFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }
}
