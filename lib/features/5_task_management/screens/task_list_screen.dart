import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/features/5_task_management/widgets/task_card.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the filtered provider to get the list of tasks to display.
    final tasksAsync = ref.watch(filteredTasksProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Assigned Tasks'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Filter Section ---
          Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Text(
              'Filter by Status',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _buildFilterChips(context, ref),
          const Divider(height: 1),

          // --- Live Task List Section ---
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppPadding.large),
                      child: Text(
                        'No tasks match the current filter.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppPadding.medium),
                      child: TaskCard(task: tasks[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// A helper widget to build the row of filter chips.
  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(taskFilterProvider);

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
        children: TaskFilter.values.map((filter) {
          final isSelected = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter.name[0].toUpperCase() + filter.name.substring(1)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // When a chip is tapped, update the state of the filter provider.
                  ref.read(taskFilterProvider.notifier).state = filter;
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
