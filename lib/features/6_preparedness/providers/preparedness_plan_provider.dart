import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/preparedness_model.dart';

/// A provider that manages the business logic for the preparedness plan.
final preparednessControllerProvider =
StateNotifierProvider<PreparednessController, bool>((ref) {
  return PreparednessController(ref);
});

class PreparednessController extends StateNotifier<bool> {
  final Ref _ref;
  PreparednessController(this._ref) : super(false);

  /// Toggles the completion status of a checklist item in Firestore.
  Future<void> toggleItemStatus(String itemId, bool currentStatus) async {
    // Get the current user from the live auth provider.
    final user = _ref.read(authStateChangesProvider).value;
    if (user == null) return; // Do nothing if the user is not logged in.

    // Call the database service to update the item's status in Firestore.
    await _ref
        .read(databaseServiceProvider)
        .updatePreparednessItemStatus(user.uid, itemId, !currentStatus);
  }
}

/// A StreamProvider that provides a live stream of the user's preparedness plan from Firestore.
///
/// It also intelligently checks for and creates a default plan for the user the
/// first time they access this feature, ensuring every user has a checklist.
final preparednessPlanProvider = StreamProvider.autoDispose<List<PreparednessItem>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final dbService = ref.watch(databaseServiceProvider);

  if (user != null) {
    // 1. Check for and create the default plan if it's the user's first time.
    // Use async to avoid blocking and handle errors gracefully
    Future(() async {
      try {
        await dbService.checkAndCreateDefaultPlan(user.uid);
      } catch (e) {
        // Silently fail in production or log to crashlytics
      }
    });
    
    // 2. Return the live stream of their personal plan from the sub-collection.
    return dbService.getPreparednessPlanStream(user.uid).handleError((error) {
      return <PreparednessItem>[];
    });
  }

  // If the user is logged out, return an empty stream.
  return Stream.value([]);
});

/// A derived provider that calculates the completion percentage from the live data stream.
/// It correctly handles the loading, error, and data states of the stream.
final preparednessProgressProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  final planAsync = ref.watch(preparednessPlanProvider);
  return planAsync.when(
    data: (items) {
      if (items.isEmpty) return const AsyncData(0.0);
      final completedItems = items.where((item) => item.isCompleted).length;
      return AsyncData(completedItems / items.length);
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

