import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/task_model.dart';
import 'package:rescuetn/models/user_model.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';

// ... existing code ...

// 5. Provider to fetch the assigned volunteer's details
final volunteerDetailsProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final taskAsync = ref.watch(selectedTaskProvider);
  
  return taskAsync.when(
    data: (task) async {
      if (task == null || task.assignedTo == null || task.assignedTo!.isEmpty) {
        return null;
      }
      
      final databaseService = ref.read(databaseServiceProvider);
      try {
        // Fetch the user record for the assigned volunteer
        return await databaseService.getUserRecord(task.assignedTo!);
      } catch (e) {
        debugPrint('Error fetching volunteer details: $e');
        return null;
      }
    },
    loading: () => null, // Return null while loading parent task
    error: (_, __) => null,
  );
});

/// This file has been updated to provide a live stream of task data from Firestore,
/// replacing the local dummy data.

// 1. A StreamProvider that provides a real-time stream of all tasks from Firestore.
// The UI will listen to this to get the initial, unfiltered list of tasks.
final tasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  // If auth is loading, don't return empty list yet. Keep this provider loading.
  if (authState.isLoading) {
    return const Stream.empty(); 
  }

  // Return empty stream if user is not logged in to prevent permission denied errors
  if (authState.valueOrNull == null) {
    return Stream.value([]);
  }

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.getTasksStream();
});

// 2. A provider to hold the current filter state (e.g., 'all', 'pending').
enum TaskFilter { all, pending, inProgress, accepted, completed }
final taskFilterProvider = StateProvider.autoDispose<TaskFilter>((ref) => TaskFilter.all);

// 3. A derived provider that returns the filtered list of tasks.
// It watches the stream and the filter provider, and returns a new list
// whenever either one changes. It also handles loading and error states.
final filteredTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final tasksAsync = ref.watch(tasksStreamProvider);

  return tasksAsync.when(
    data: (tasks) {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return const AsyncData([]);

      // Filter by assignment first (Show tasks assigned to THIS volunteer OR unassigned pending tasks)
      final myTasks = tasks.where((t) {
        final assignedTo = t.assignedTo;
        final isAssignedToMe = assignedTo == user.uid || 
                             (assignedTo != null && assignedTo.isNotEmpty && (
                               assignedTo == user.email || 
                               (user.fullName != null && assignedTo == user.fullName) ||
                               (user.phoneNumber.isNotEmpty && assignedTo == user.phoneNumber)
                             ));
        final isUnassignedPending = (assignedTo == null || assignedTo.isEmpty) && t.status == TaskStatus.pending;
        return isAssignedToMe || isUnassignedPending;
      }).toList();

      if (filter == TaskFilter.all) {
        return AsyncData(myTasks);
      } else {
        final correspondingStatus = TaskStatus.values.firstWhere(
              (status) => status.name == filter.name,
        );
        final filteredList =
        myTasks.where((task) => task.status == correspondingStatus).toList();
        return AsyncData(filteredList);
      }
    },
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
  );
});

// 4. Providers for selecting a specific task.
final selectedTaskIdProvider = StateProvider.autoDispose<String?>((ref) => null);

final selectedTaskProvider = FutureProvider.autoDispose<Task?>((ref) async {
  final selectedId = ref.watch(selectedTaskIdProvider);
  if (selectedId == null) return null;

  final tasksAsync = ref.watch(tasksStreamProvider);
  
  // 1. Try to find in the existing stream first (fastest)
  if (tasksAsync.hasValue) {
    try {
      return tasksAsync.value!.firstWhere((task) => task.id == selectedId);
    } catch (_) {
      // Not found in stream, proceed to step 2
    }
  }

  // 2. If not in stream (or stream loading/error), fetch directly from DB
  final databaseService = ref.read(databaseServiceProvider);
  try {
    return await databaseService.getTask(selectedId);
  } catch (e) {
    debugPrint('Error fetching selected task: $e');
    // If it's a permission denied error, rethrow it so UI can show appropriate message
    if (e.toString().contains('permission-denied')) {
      rethrow;
    }
    return null;
  }
});

