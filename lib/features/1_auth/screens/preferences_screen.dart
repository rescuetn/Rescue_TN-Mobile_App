import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/constants.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  bool _pushNotifications = true;
  bool _locationServices = true;
  bool _emailNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppPadding.large),
        children: [
          const SizedBox(height: AppPadding.medium),
          const Icon(
            Icons.settings,
            size: 60,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppPadding.large),
          const Text(
            'App Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppPadding.xLarge),

          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Push Notifications',
            'Receive emergency alerts and updates',
            Icons.notifications_active,
            _pushNotifications,
            (value) {
              setState(() => _pushNotifications = value);
              _showSnackBar(context, value ? 'Push notifications enabled' : 'Push notifications disabled');
            },
          ),
          _buildSwitchTile(
            'Email Notifications',
            'Receive updates via email',
            Icons.email,
            _emailNotifications,
            (value) {
              setState(() => _emailNotifications = value);
              _showSnackBar(context, value ? 'Email notifications enabled' : 'Email notifications disabled');
            },
          ),
          _buildSwitchTile(
            'Sound',
            'Play sound for notifications',
            Icons.volume_up,
            _soundEnabled,
            (value) {
              setState(() => _soundEnabled = value);
              _showSnackBar(context, value ? 'Sound enabled' : 'Sound disabled');
            },
          ),
          _buildSwitchTile(
            'Vibration',
            'Vibrate for notifications',
            Icons.vibration,
            _vibrationEnabled,
            (value) {
              setState(() => _vibrationEnabled = value);
              _showSnackBar(context, value ? 'Vibration enabled' : 'Vibration disabled');
            },
          ),

          const SizedBox(height: AppPadding.large),
          _buildSectionHeader('Services'),
          _buildSwitchTile(
            'Location Services',
            'Share location for emergency response',
            Icons.location_on,
            _locationServices,
            (value) {
              setState(() => _locationServices = value);
              _showSnackBar(context, value ? 'Location services enabled' : 'Location services disabled');
            },
          ),

          const SizedBox(height: AppPadding.xLarge),
          _buildSectionHeader('About'),
          _buildInfoTile(
            'App Version',
            '1.0.0',
            Icons.info,
          ),
          _buildInfoTile(
            'Build Number',
            '1',
            Icons.build,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.medium, top: AppPadding.medium),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(value, style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

