import 'package:flutter/foundation.dart';
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
/// It ensures default plan items are created before streaming data.
final preparednessPlanProvider = StreamProvider.autoDispose<List<PreparednessItem>>((ref) async* {
  final userAsync = ref.watch(authStateChangesProvider);
  
  final user = userAsync.valueOrNull;
  if (user == null) {
    yield [];
    return;
  }

  final dbService = ref.watch(databaseServiceProvider);

  // First, ensure the default plan exists (await this to ensure it completes)
  try {
    await dbService.checkAndCreateDefaultPlan(user.uid);
  } catch (e) {
    debugPrint('Error preparing default plan: $e');
  }
  
  // Then stream the live data
  yield* dbService.getPreparednessPlanStream(user.uid);
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
