import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rescuetn/models/alert_model.dart';
import 'package:rescuetn/app/constants.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  
  const AlertCard({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getCardColor(alert.level, isDarkMode);
    final backgroundColor = _getBackgroundColor(alert.level, isDarkMode);

    return GestureDetector(
      onTap: onTap ?? () => _showAlertDetailsDialog(context),
      child: Card(
        elevation: 4,
        color: backgroundColor,
        shadowColor: accentColor.withValues(alpha: 0.3),
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
                backgroundColor.withValues(alpha: 0.8),
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
                        color: accentColor.withValues(alpha: 0.2),
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
                    // Tap indicator
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accentColor.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.3),
                        accentColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  alert.message,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.black87.withValues(alpha: 0.85),
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
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black54.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
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
      ),
    );
  }

  /// Show alert details dialog
  void _showAlertDetailsDialog(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getCardColor(alert.level, isDarkMode);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.1),
                isDarkMode ? Colors.grey.shade900 : Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(alert.level),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getLevelLabel(alert.level),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message Section
                      _buildDetailSection(
                        context,
                        icon: Icons.message_rounded,
                        title: 'Message',
                        accentColor: accentColor,
                        child: Text(
                          alert.message,
                          style: textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: isDarkMode ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Timestamp Section
                      _buildDetailSection(
                        context,
                        icon: Icons.access_time_rounded,
                        title: 'Issued At',
                        accentColor: accentColor,
                        child: Text(
                          DateFormat('EEEE, MMMM d, yyyy\nh:mm a')
                              .format(alert.timestamp),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ),

                      // Target Roles (if any)
                      if (alert.targetRoles != null &&
                          alert.targetRoles!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection(
                          context,
                          icon: Icons.people_rounded,
                          title: 'Target Audience',
                          accentColor: accentColor,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: alert.targetRoles!.map((role) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Image (if any)
                      if (alert.imageUrl != null &&
                          alert.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection(
                          context,
                          icon: Icons.image_rounded,
                          title: 'Attachment',
                          accentColor: accentColor,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              alert.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 150,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a detail section with icon and title
  Widget _buildDetailSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
            ),
          ),
          child: child,
        ),
      ],
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
          return Colors.red.shade900.withValues(alpha: 0.3);
        case AlertLevel.warning:
          return Colors.orange.shade900.withValues(alpha: 0.3);
        case AlertLevel.info:
          return Colors.blue.shade900.withValues(alpha: 0.3);
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
