import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/features/5_task_management/widgets/task_card.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/task_model.dart';
import 'package:rescuetn/models/user_model.dart';

class VolunteerDashboardScreen extends ConsumerStatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  ConsumerState<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState
    extends ConsumerState<VolunteerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Updates volunteer status in Firestore
  Future<void> _updateVolunteerStatus(VolunteerStatus newStatus) async {
    setState(() => _isUpdatingStatus = true);

    try {
      final authService = ref.read(authRepositoryProvider);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final databaseService = ref.read(databaseServiceProvider);

        // Create updated user with new status
        final updatedUser = currentUser.copyWith(status: newStatus);

        // Update in Firestore
        await databaseService.updateUserRecord(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(newStatus.icon, color: Colors.white),
                  const SizedBox(width: AppPadding.small),
                  Text('Status: ${newStatus.label}'),
                ],
              ),
              backgroundColor: newStatus.color,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              margin: const EdgeInsets.all(AppPadding.medium),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Text(
                    'Failed to update status: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            margin: const EdgeInsets.all(AppPadding.medium),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  /// Show settings/logout dialog
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppPadding.large),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade500, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Center(
                child: Text(
                  'Settings & Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Menu Items
            Padding(
              padding: const EdgeInsets.all(AppPadding.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Option
                  _buildSettingsMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    subtitle: 'View and edit your profile',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  const SizedBox(height: AppPadding.medium + 4),

                  // Preferences Option
                  _buildSettingsMenuItem(
                    icon: Icons.tune_outlined,
                    title: 'Preferences',
                    subtitle: 'App settings and notifications',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/preferences');
                    },
                  ),
                  const SizedBox(height: AppPadding.medium + 4),

                  // Help & Support Option
                  _buildSettingsMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and report issues',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/help-center');
                    },
                  ),
                  const SizedBox(height: AppPadding.medium + 4),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  const SizedBox(height: AppPadding.medium + 4),

                  // Logout Option
                  _buildSettingsMenuItem(
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    subtitle: 'Sign out from your account',
                    color: AppColors.error,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.medium),
          ],
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            const Text(
              'Logout?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authService = ref.read(authRepositoryProvider);
                await authService.signOut();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual settings menu item
  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Container(
          padding: const EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDestructive ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final allTasksAsync = ref.watch(tasksStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade800,
              Colors.red.shade700,
              Colors.red.shade600,
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.15, 0.28, 0.28],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced App Bar with Status Toggle and Settings
                  Padding(
                    padding: const EdgeInsets.all(AppPadding.large),
                    child: authState.when(
                      data: (user) {
                        final email = user?.email ?? '';
                        String userName = email.isNotEmpty ? email.split('@').first : 'Volunteer';
                        if (userName.isNotEmpty) {
                          userName = userName.substring(0, 1).toUpperCase() + userName.substring(1);
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppPadding.medium),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium + 2),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety,
                                    color: AppColors.onPrimary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium + 2),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RescueTN',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        letterSpacing: 0.8,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.25),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppPadding.small + 4,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.accent, Color(0xFFFFA726)],
                                        ),
                                        borderRadius: BorderRadius.circular(AppBorderRadius.small + 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accent.withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'VOLUNTEER',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: AppColors.onAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Status Menu
                                PopupMenuButton<VolunteerStatus>(
                                  initialValue: user?.status ?? VolunteerStatus.available,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                                  ),
                                  onSelected: (newStatus) {
                                    _updateVolunteerStatus(newStatus);
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return VolunteerStatus.values.map((status) {
                                      final isSelected = status == (user?.status ?? VolunteerStatus.available);
                                      return PopupMenuItem<VolunteerStatus>(
                                        value: status,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: status.color.withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                status.icon,
                                                size: 18,
                                                color: status.color,
                                              ),
                                            ),
                                            const SizedBox(width: AppPadding.medium),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  status.label,
                                                  style: TextStyle(
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                    color: isSelected ? status.color : AppColors.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  status.description,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isSelected)
                                              const Padding(
                                                padding: EdgeInsets.only(left: AppPadding.medium),
                                                child: Icon(Icons.check, color: AppColors.primary),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              (user?.status ?? VolunteerStatus.available).color.withOpacity(0.9),
                                              (user?.status ?? VolunteerStatus.available).color.withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(AppBorderRadius.medium + 2),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (user?.status ?? VolunteerStatus.available).color.withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppPadding.medium,
                                            vertical: AppPadding.small + 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                (user?.status ?? VolunteerStatus.available).icon,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                user?.status?.label ?? 'Available',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_isUpdatingStatus)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(0.3),
                                            ),
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium),
                                // Settings Icon
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium + 2),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.settings_applications),
                                    color: AppColors.onPrimary,
                                    iconSize: 24,
                                    tooltip: 'Settings',
                                    onPressed: _showSettingsMenu,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const Text('Error loading user', style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  // Welcome Card and rest of the dashboard...
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Enhanced Welcome Card with Statistics
                          allTasksAsync.when(
                            data: (allTasks) {
                              final pendingCount = allTasks.where((t) => t.status == TaskStatus.pending).length;
                              final activeCount = allTasks.where((t) => t.status == TaskStatus.inProgress || t.status == TaskStatus.accepted).length;
                              final completedCount = allTasks.where((t) => t.status == TaskStatus.completed).length;
                              final email = authState.value?.email ?? '';
                              final userName = email.isNotEmpty ? email.split('@').first : 'Volunteer';
                              final formattedUserName = userName.isNotEmpty
                                  ? userName.substring(0, 1).toUpperCase() + userName.substring(1)
                                  : 'Volunteer';

                              return Container(
                                margin: const EdgeInsets.fromLTRB(
                                  AppPadding.large,
                                  AppPadding.small,
                                  AppPadding.large,
                                  AppPadding.medium,
                                ),
                                padding: const EdgeInsets.all(AppPadding.large + 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppPadding.medium + 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.red.shade500, Colors.red.shade700],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(AppBorderRadius.large + 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.4),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.volunteer_activism,
                                            color: AppColors.onPrimary,
                                            size: 36,
                                          ),
                                        ),
                                        const SizedBox(width: AppPadding.large),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Welcome back,',
                                                style: textTheme.bodyMedium?.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formattedUserName,
                                                style: textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                  fontSize: 26,
                                                  letterSpacing: 0.3,
                                                  height: 1.2,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppPadding.large + 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            label: 'Pending',
                                            count: pendingCount,
                                            color: Colors.orange.shade600,
                                            icon: Icons.pending_actions,
                                          ),
                                        ),
                                        const SizedBox(width: AppPadding.medium + 2),
                                        Expanded(
                                          child: _buildStatCard(
                                            label: 'Active',
                                            count: activeCount,
                                            color: Colors.blue.shade600,
                                            icon: Icons.trending_up,
                                          ),
                                        ),
                                        const SizedBox(width: AppPadding.medium + 2),
                                        Expanded(
                                          child: _buildStatCard(
                                            label: 'Done',
                                            count: completedCount,
                                            color: Colors.green.shade600,
                                            icon: Icons.check_circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => Container(
                              margin: const EdgeInsets.symmetric(horizontal: AppPadding.large, vertical: AppPadding.small),
                              padding: const EdgeInsets.all(AppPadding.xLarge),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.15),
                                    blurRadius: 25,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                              ),
                            ),
                            error: (e, s) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: AppPadding.large, vertical: AppPadding.small),
                              padding: const EdgeInsets.all(AppPadding.large),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Center(
                                child: Text('Error loading stats', style: TextStyle(color: AppColors.error)),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppPadding.small),

                          // Enhanced Situational Awareness Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.15),
                                        AppColors.primary.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.radar,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium + 2),
                                Text(
                                  'Situational Awareness',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 19,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppPadding.medium),

                          // Enhanced Horizontal Scrollable Cards
                          SizedBox(
                            height: 160,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildAwarenessCard(
                                  title: 'Live Heatmap',
                                  subtitle: 'Disaster hotspots',
                                  icon: Icons.local_fire_department,
                                  gradient: LinearGradient(
                                    colors: [Colors.amber.shade600, Colors.deepOrange.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () => context.go('/heatmap'),
                                ),
                                const SizedBox(width: AppPadding.medium + 4),
                                _buildAwarenessCard(
                                  title: 'Find Shelters',
                                  subtitle: 'Safe locations',
                                  icon: Icons.maps_home_work_rounded,
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade500, Colors.teal.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () => context.go('/shelter-map'),
                                ),
                                const SizedBox(width: AppPadding.medium + 4),
                                _buildAwarenessCard(
                                  title: 'View Alerts',
                                  subtitle: 'Stay informed',
                                  icon: Icons.notifications_active,
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade500, Colors.indigo.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  onTap: () => context.go('/alerts'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppPadding.large),

                          // Enhanced Filter Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.15),
                                        AppColors.primary.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium + 2),
                                Text(
                                  'Filter Tasks',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 19,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppPadding.medium + 2),

                          // Enhanced Filter Chips
                          _buildFilterChips(context, ref),

                          const SizedBox(height: AppPadding.large),

                          // Enhanced Task List Header
                          filteredTasksAsync.when(
                            data: (tasks) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.withOpacity(0.15),
                                              Colors.red.withOpacity(0.08),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.assignment_turned_in,
                                          color: Colors.red,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: AppPadding.medium + 2),
                                      Text(
                                        'Assigned Tasks',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          fontSize: 22,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppPadding.medium + 4,
                                      vertical: AppPadding.small + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.red.shade500, Colors.red.shade600],
                                      ),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.large),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${tasks.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),

                          const SizedBox(height: AppPadding.medium),

                          // Task List Section
                          filteredTasksAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            ),
                            error: (err, stack) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppPadding.xLarge),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.error.withOpacity(0.1),
                                          AppColors.error.withOpacity(0.05),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 72,
                                      color: AppColors.error.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.large),
                                  Text(
                                    'Failed to load tasks',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.small + 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppPadding.xLarge + 8),
                                    child: Text(
                                      err.toString(),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            data: (tasks) => tasks.isEmpty
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppPadding.xLarge + 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.withOpacity(0.1),
                                          Colors.red.withOpacity(0.05),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.task_alt,
                                      size: 80,
                                      color: Colors.red.withOpacity(0.4),
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.large + 4),
                                  Text(
                                    'No tasks found',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontSize: 24,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.small + 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppPadding.xLarge + 8,
                                    ),
                                    child: Text(
                                      'No tasks match the current filter.\nTry selecting a different filter.',
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : ListView.builder(
                              padding: const EdgeInsets.all(AppPadding.large),
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppPadding.medium + 4,
                                  ),
                                  child: TaskCard(task: tasks[index]),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAwarenessCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.large + 2),
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(AppPadding.large),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppBorderRadius.large + 2),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.medium),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium + 2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
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

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium + 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(taskFilterProvider);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
        physics: const BouncingScrollPhysics(),
        children: TaskFilter.values.map((filter) {
          final isSelected = filter == currentFilter;

          IconData filterIcon;
          Color filterColor;
          switch (filter) {
            case TaskFilter.all:
              filterIcon = Icons.grid_view_rounded;
              filterColor = AppColors.primary;
              break;
            case TaskFilter.pending:
              filterIcon = Icons.pending_actions;
              filterColor = Colors.orange.shade600;
              break;
            case TaskFilter.inProgress:
              filterIcon = Icons.trending_up;
              filterColor = Colors.blue.shade600;
              break;
            case TaskFilter.completed:
              filterIcon = Icons.check_circle;
              filterColor = Colors.green.shade600;
              break;
            default:
              filterIcon = Icons.filter_list;
              filterColor = AppColors.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppPadding.medium + 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(taskFilterProvider.notifier).state = filter;
                },
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.large,
                    vertical: AppPadding.medium,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: [filterColor, filterColor.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                    border: Border.all(
                      color: isSelected
                          ? filterColor
                          : AppColors.textSecondary.withOpacity(0.25),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: filterColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filterIcon,
                        size: 20,
                        color: isSelected ? Colors.white : filterColor,
                      ),
                      const SizedBox(width: AppPadding.small + 2),
                      Text(
                        filter.name[0].toUpperCase() +
                            filter.name.substring(1).replaceAll(RegExp(r'([A-Z])'), ' P'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 15,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}