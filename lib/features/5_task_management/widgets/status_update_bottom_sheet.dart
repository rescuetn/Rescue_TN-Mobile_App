import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/task_model.dart';

class StatusUpdateBottomSheet extends ConsumerWidget {
  final Task currentTask;
  const StatusUpdateBottomSheet({super.key, required this.currentTask});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.accent.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.update_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Update Task Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...TaskStatus.values.map((status) {
                // Skip if it's the current status, optional
                if (status == currentTask.status) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEnhancedStatusOption(context, ref, status),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusOption(
    BuildContext context,
    WidgetRef ref,
    TaskStatus status,
  ) {
    final gradient = _getStatusGradient(status);
    final icon = _getStatusIcon(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          try {
            await ref
                .read(databaseServiceProvider)
                .updateTaskStatus(currentTask.id, status);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Status updated to ${status.name.toUpperCase()}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  backgroundColor: gradient[1],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating status: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient[0].withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  status == TaskStatus.inProgress
                      ? 'ACTIVE'
                      : status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: gradient[1],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: gradient[0].withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getStatusGradient(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case TaskStatus.accepted:
        return [Colors.cyan.shade400, Colors.cyan.shade600];
      case TaskStatus.inProgress:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case TaskStatus.completed:
        return [Colors.green.shade400, Colors.green.shade600];
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending_actions_rounded;
      case TaskStatus.accepted:
        return Icons.thumb_up_alt_rounded;
      case TaskStatus.inProgress:
        return Icons.work_rounded;
      case TaskStatus.completed:
        return Icons.check_circle_rounded;
    }
  }
}

