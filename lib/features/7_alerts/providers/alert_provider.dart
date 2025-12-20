import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/alert_model.dart';

/// This file provides the logic for fetching and filtering live alert data from Firebase.

// 1. An enum to represent the different filter states for the UI.
enum AlertFilter { all, severe, warning, info }

// 2. A StateProvider to hold the user's current filter selection.
// The UI will update this provider when the user taps a filter chip.
final alertFilterProvider = StateProvider.autoDispose<AlertFilter>((ref) => AlertFilter.all);

// 3. A StreamProvider that provides a real-time stream of all alerts from Firestore.
// This is the main source of live data.
// 3. A StreamProvider that provides a real-time stream of all alerts from Firestore.
// This is the main source of live data.
final alertsStreamProvider = StreamProvider.autoDispose<List<Alert>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) {
      return Stream.value([]);
  }
  
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getAlertsStream();
});

// 4. A derived Provider that returns a filtered list of alerts.
// It watches both the main data stream and the filter provider, and automatically
// recalculates the list whenever either one changes. It returns an AsyncValue
// to handle loading and error states gracefully.
final filteredAlertsProvider = Provider.autoDispose<AsyncValue<List<Alert>>>((ref) {
  final filter = ref.watch(alertFilterProvider);
  final alertsAsync = ref.watch(alertsStreamProvider);

  return alertsAsync.when(
    data: (alerts) {
      if (filter == AlertFilter.all) {
        // If the filter is 'all', return the full list.
        return AsyncData(alerts);
      } else {
        // Otherwise, filter the list based on the selected level.
        final correspondingLevel = AlertLevel.values.firstWhere(
              (level) => level.name == filter.name,
          orElse: () => AlertLevel.info, // Fallback
        );
        final filteredList =
        alerts.where((alert) => alert.level == correspondingLevel).toList();
        return AsyncData(filteredList);
      }
    },
    // Pass along the loading and error states from the main stream.
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

