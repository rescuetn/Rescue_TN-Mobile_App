import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/task_model.dart';

/// This file has been updated to provide a live stream of task data from Firestore,
/// replacing the local dummy data.

// 1. A StreamProvider that provides a real-time stream of all tasks from Firestore.
// The UI will listen to this to get the initial, unfiltered list of tasks.
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.getTasksStream();
});

// 2. A provider to hold the current filter state (e.g., 'all', 'pending').
enum TaskFilter { all, pending, inProgress, accepted, completed }
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

// 3. A derived provider that returns the filtered list of tasks.
// It watches the stream and the filter provider, and returns a new list
// whenever either one changes. It also handles loading and error states.
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final tasksAsync = ref.watch(tasksStreamProvider);

  return tasksAsync.when(
    data: (tasks) {
      if (filter == TaskFilter.all) {
        return AsyncData(tasks);
      } else {
        final correspondingStatus = TaskStatus.values.firstWhere(
              (status) => status.name == filter.name,
        );
        final filteredList =
        tasks.where((task) => task.status == correspondingStatus).toList();
        return AsyncData(filteredList);
      }
    },
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
  );
});

// 4. Providers for selecting a specific task.
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);

final selectedTaskProvider = Provider<Task?>((ref) {
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

