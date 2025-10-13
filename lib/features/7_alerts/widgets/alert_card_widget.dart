import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rescuetn/models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      color: _getCardColor(alert.level).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getCardColor(alert.level), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(alert.level), color: _getCardColor(alert.level)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.title,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(alert.message, style: textTheme.bodyLarge),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('MMM d, yyyy - h:mm a').format(alert.timestamp),
                style: textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.severe:
        return Colors.red.shade700;
      case AlertLevel.warning:
        return Colors.orange.shade700;
      case AlertLevel.info:
        return Colors.blue.shade700;
    }
  }

  IconData _getIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.severe:
        return Icons.error_outline;
      case AlertLevel.warning:
        return Icons.warning_amber_rounded;
      case AlertLevel.info:
        return Icons.info_outline;
    }
  }
}
