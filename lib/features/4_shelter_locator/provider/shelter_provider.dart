import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/shelter_model.dart';

/// A StreamProvider that provides a real-time stream of all shelters from Firestore.
///
/// This provider watches the `getSheltersStream` method from our `DatabaseService`.
/// Any widget that watches this provider (like the ShelterMapScreen) will automatically
/// rebuild with the latest data whenever a shelter's information is added, updated,
/// or removed in the 'shelters' collection in Firestore.
final shelterStreamProvider = StreamProvider<List<Shelter>>((ref) {
  // Get an instance of our database service.
  final databaseService = ref.watch(databaseServiceProvider);
  // Return the live stream of shelter data.
  return databaseService.getSheltersStream();
});

