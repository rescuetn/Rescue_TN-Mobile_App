import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/task_model.dart';

/// This file has been updated to provide a live stream of task data from Firestore,
/// replacing the local dummy data.

// 1. A StreamProvider that provides a real-time stream of all tasks from Firestore.
// The UI will listen to this to get the initial, unfiltered list of tasks.
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';

// 1. A StreamProvider that provides a real-time stream of all tasks from Firestore.
// The UI will listen to this to get the initial, unfiltered list of tasks.
// 1. A StreamProvider that provides a real-time stream of all tasks from Firestore.
// The UI will listen to this to get the initial, unfiltered list of tasks.
final tasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
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

      // Filter by assignment first (Show only tasks assigned to THIS volunteer)
      final myTasks = tasks.where((t) => t.assignedTo == user.uid).toList();

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

final selectedTaskProvider = Provider.autoDispose<Task?>((ref) {
  final selectedId = ref.watch(selectedTaskIdProvider);
  final tasksAsync = ref.watch(tasksStreamProvider);

  // We can only find the task if the stream has successfully loaded data.
  return tasksAsync.when(
    data: (tasks) {
      if (selectedId == null) return null;
      try {
        return tasks.firstWhere((task) => task.id == selectedId);
      } catch (e) {
        return null; // Return null if the task is not found in the list.
      }
    },
    // In loading or error states, there is no selected task.
    loading: () => null,
    error: (_, __) => null,
  );
});

