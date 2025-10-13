import 'package:flutter/material.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/models/shelter_model.dart';

class ShelterDetailsBottomSheet extends StatelessWidget {
  final Shelter shelter;
  const ShelterDetailsBottomSheet({super.key, required this.shelter});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final occupancyPercentage = (shelter.currentOccupancy / shelter.capacity) * 100;

    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shelter.name, style: textTheme.headlineSmall),
          const SizedBox(height: AppPadding.medium),
          _buildInfoRow(
            Icons.people_alt_outlined,
            'Occupancy: ${shelter.currentOccupancy} / ${shelter.capacity}',
          ),
          const SizedBox(height: AppPadding.small),
          // --- Occupancy Progress Bar ---
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            child: LinearProgressIndicator(
              value: occupancyPercentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                occupancyPercentage > 90 ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          _buildInfoRow(
            _getStatusIcon(shelter.status),
            'Status: ${_getStatusText(shelter.status)}',
            color: _getStatusColor(shelter.status),
          ),
          const SizedBox(height: AppPadding.large),
          // In a real app, this would open Google Maps for navigation
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.directions),
            label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
        const SizedBox(width: AppPadding.medium),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  IconData _getStatusIcon(ShelterStatus status) {
    switch (status) {
      case ShelterStatus.available:
        return Icons.check_circle_outline;
      case ShelterStatus.full:
        return Icons.warning_amber_rounded;
      case ShelterStatus.closed:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusText(ShelterStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  Color _getStatusColor(ShelterStatus status) {
    switch (status) {
      case ShelterStatus.available:
        return Colors.green.shade700;
      case ShelterStatus.full:
        return Colors.orange.shade700;
      case ShelterStatus.closed:
        return Colors.red.shade700;
    }
  }
}
