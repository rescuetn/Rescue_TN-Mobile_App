import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/shelter_model.dart';

/// An enum to represent the different filter states for the UI.
enum ShelterFilter { all, available, full, closed }

/// A StateProvider to hold the user's current filter selection.
final shelterFilterProvider = StateProvider<ShelterFilter>((ref) => ShelterFilter.all);

/// A StreamProvider that provides a real-time stream of all shelters from Firestore.
final shelterStreamProvider = StreamProvider<List<Shelter>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.getSheltersStream();
});

/// A derived Provider that returns a filtered list of shelters.
/// It watches both the main data stream and the filter provider.
final filteredShelterProvider = Provider<AsyncValue<List<Shelter>>>((ref) {
  final filter = ref.watch(shelterFilterProvider);
  final sheltersAsync = ref.watch(shelterStreamProvider);

  return sheltersAsync.when(
    data: (shelters) {
      if (filter == ShelterFilter.all) {
        return AsyncData(shelters);
      }
      final correspondingStatus = ShelterStatus.values.firstWhere((s) => s.name == filter.name);
      final filteredList = shelters.where((s) => s.status == correspondingStatus).toList();
      return AsyncData(filteredList);
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

