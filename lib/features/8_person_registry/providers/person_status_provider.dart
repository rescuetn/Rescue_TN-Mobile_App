import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/person_status_model.dart';

/// A StreamProvider that provides a real-time stream of all person status reports.
///
/// This provider watches the `getPersonStatusStream` method from our `DatabaseService`.
/// Any widget that watches this provider will automatically rebuild with the latest
/// data whenever a new report is added to the 'person_statuses' collection in Firestore.
final personStatusStreamProvider = StreamProvider.autoDispose<List<PersonStatus>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) {
    return Stream.value([]);
  }

  // Get an instance of our database service.
  final databaseService = ref.watch(databaseServiceProvider);
  // Return the stream of person status reports.
  return databaseService.getPersonStatusStream();
});

