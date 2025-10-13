import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(userStateProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Profile Header ---
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person_outline,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppPadding.medium),
            Text(
              user?.email ?? 'User Email',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              'Role: ${user?.role.name.toUpperCase() ?? 'N/A'}',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const Divider(height: AppPadding.large),

            // --- Menu Options (Placeholders) ---
            _buildProfileOption(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to an edit profile screen
              },
            ),
            _buildProfileOption(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                // TODO: Navigate to a settings screen
              },
            ),
            const Spacer(),

            // --- Logout Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () {
                // Setting the user state to null triggers the router to redirect.
                ref.read(userStateProvider.notifier).state = null;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

