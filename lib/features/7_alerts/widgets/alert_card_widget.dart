import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rescuetn/models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getCardColor(alert.level, isDarkMode);
    final backgroundColor = _getBackgroundColor(alert.level, isDarkMode);

    return Card(
      elevation: 4,
      color: backgroundColor,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.2),
                    ),
                    child: Icon(
                      _getIcon(alert.level),
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLevelLabel(alert.level),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.3),
                      accentColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: textTheme.bodyLarge?.copyWith(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.85)
                      : Colors.black87.withOpacity(0.85),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMM d, yyyy - h:mm a')
                          .format(alert.timestamp),
                      style: textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black54.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getLevelLabel(alert.level),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get primary accent color based on alert level and theme
  Color _getCardColor(AlertLevel level, bool isDarkMode) {
    switch (level) {
      case AlertLevel.severe:
        return isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
      case AlertLevel.warning:
        return isDarkMode ? Colors.amber.shade400 : Colors.orange.shade700;
      case AlertLevel.info:
        return isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700;
    }
  }

  /// Get background color based on alert level and theme
  Color _getBackgroundColor(AlertLevel level, bool isDarkMode) {
    if (isDarkMode) {
      switch (level) {
        case AlertLevel.severe:
          return Colors.red.shade900.withOpacity(0.3);
        case AlertLevel.warning:
          return Colors.orange.shade900.withOpacity(0.3);
        case AlertLevel.info:
          return Colors.blue.shade900.withOpacity(0.3);
      }
    } else {
      switch (level) {
        case AlertLevel.severe:
          return Colors.red.shade50;
        case AlertLevel.warning:
          return Colors.orange.shade50;
        case AlertLevel.info:
          return Colors.blue.shade50;
      }
    }
  }

  /// Get icon based on alert level
  IconData _getIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.severe:
        return Icons.error_rounded;
      case AlertLevel.warning:
        return Icons.warning_amber_rounded;
      case AlertLevel.info:
        return Icons.info_rounded;
    }
  }

  /// Get level label
  String _getLevelLabel(AlertLevel level) {
    switch (level) {
      case AlertLevel.severe:
        return 'SEVERE';
      case AlertLevel.warning:
        return 'WARNING';
      case AlertLevel.info:
        return 'INFO';
    }
  }
}
