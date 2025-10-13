import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/models/task_model.dart';

class StatusUpdateBottomSheet extends ConsumerWidget {
  final Task currentTask;
  const StatusUpdateBottomSheet({super.key, required this.currentTask});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Update Task Status',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            // Create a list of tappable tiles for each possible status.
            ...TaskStatus.values.map((status) {
              return ListTile(
                title: Text(status.name[0].toUpperCase() + status.name.substring(1)),
                // Disable the option if it's the current status
                enabled: status != currentTask.status,
                onTap: () {
                  // Call the notifier to update the task's status
                  ref.read(taskListProvider.notifier).updateTaskStatus(currentTask.id, status);
                  // Close the bottom sheet
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
