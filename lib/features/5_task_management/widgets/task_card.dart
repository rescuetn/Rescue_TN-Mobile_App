import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/models/task_model.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(task.status),
              ],
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              task.description,
              style: textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: AppPadding.large),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.orange),
                const SizedBox(width: AppPadding.small),
                Text(
                  'Severity: ${task.severity.name[0].toUpperCase()}${task.severity.name.substring(1)}',
                  style: textTheme.bodyMedium,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Set the selected task's ID in the provider
                    ref.read(selectedTaskIdProvider.notifier).state = task.id;
                    // Navigate to the details screen
                    context.go('/task-details');
                  },
                  child: const Text('View Details'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color chipColor;
    String statusText = status.name[0].toUpperCase() + status.name.substring(1);

    switch (status) {
      case TaskStatus.pending:
        chipColor = Colors.grey;
        break;
      case TaskStatus.accepted:
        chipColor = Colors.blue;
        break;
      case TaskStatus.inProgress:
        chipColor = Colors.orange;
        break;
      case TaskStatus.completed:
        chipColor = Colors.green;
        break;
    }

    return Chip(
      label: Text(statusText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }
}

