import 'package:flutter/material.dart';
import 'package:rescuetn/app/constants.dart';

/// A reusable card widget for the main dashboard actions.
class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: AppPadding.medium),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

