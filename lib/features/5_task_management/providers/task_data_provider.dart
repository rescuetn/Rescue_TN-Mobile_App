import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:rescuetn/models/task_model.dart';

// The Notifier class that will hold and manage our list of tasks.
class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier() : super(_initialTasks);

  // Method to update the status of a specific task.
  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    state = [
      for (final task in state)
        if (task.id == taskId)
          task.copyWith(status: newStatus)
        else
          task,
    ];
  }
}

// The StateNotifierProvider that the UI will interact with.
final taskListProvider =
StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier();
});

// --- NEW: A provider to hold the current filter state ---
// We add an extra 'all' status for filtering purposes.
enum TaskFilter { all, pending, inProgress, completed }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

// --- NEW: A derived provider that returns the filtered list of tasks ---
final filteredTaskListProvider = Provider<List<Task>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final tasks = ref.watch(taskListProvider);

  if (filter == TaskFilter.all) {
    return tasks;
  } else {
    // This maps our TaskFilter enum to the TaskStatus enum.
    // It's a bit complex but allows for a clean filter implementation.
    final correspondingStatus = TaskStatus.values.firstWhere(
          (status) => status.name == filter.name,
    );
    return tasks.where((task) => task.status == correspondingStatus).toList();
  }
});


// Providers for selecting a task remain the same.
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);

final selectedTaskProvider = Provider<Task?>((ref) {
  final selectedId = ref.watch(selectedTaskIdProvider);
  final tasks = ref.watch(taskListProvider);
  if (selectedId == null) return null;
  try {
    return tasks.firstWhere((task) => task.id == selectedId);
  } catch (e) {
    return null; // Return null if not found
  }
});


// The initial dummy data for our notifier.
const List<Task> _initialTasks = [
  Task(
    id: 'task001',
    title: 'Investigate Reported Fire',
    incidentId: 'inc001',
    description: 'A fire was reported near T. Nagar. Assess the situation and report back.',
    severity: Severity.high,
    status: TaskStatus.pending,
  ),
  Task(
    id: 'task002',
    title: 'Deliver Medical Supplies',
    incidentId: 'inc002',
    description: 'Deliver first aid kits to the shelter at Marina Beach.',
    severity: Severity.medium,
    status: TaskStatus.inProgress,
  ),
  Task(
    id: 'task003',
    title: 'Assist in Water Evacuation',
    incidentId: 'inc003',
    description: 'A residential area in Velachery is flooded. Assist with boat evacuation.',
    severity: Severity.critical,
    status: TaskStatus.accepted,
  ),
  Task(
    id: 'task004',
    title: 'Clear Fallen Tree',
    incidentId: 'inc004',
    description: 'A large tree has fallen and is blocking the main road in Adyar.',
    severity: Severity.high,
    status: TaskStatus.pending,
  ),
  Task(
    id: 'task005',
    title: 'Distribute Food Packets',
    incidentId: 'inc005',
    description: 'Distribute food and water at the Guindy relief camp.',
    severity: Severity.low,
    status: TaskStatus.completed,
  ),
  Task(
    id: 'task006',
    title: 'Transport Stranded Citizens',
    incidentId: 'inc006',
    description: 'Use the provided vehicle to transport 10 people from Saidapet bridge to the nearest shelter.',
    severity: Severity.critical,
    status: TaskStatus.inProgress,
  ),
];

