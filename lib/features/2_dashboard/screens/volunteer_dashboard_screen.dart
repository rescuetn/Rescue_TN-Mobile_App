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
import 'package:rescuetn/core/providers/locale_provider.dart';

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
                  Text('${"dashboard.status".tr(context)}: ${"volunteerStatus.${newStatus.name}".tr(context)}'),
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
              color: Colors.black.withValues(alpha: 0.1),
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
                  "settings.title".tr(context),
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
                    title: "settings.profile".tr(context),
                    subtitle: "View and edit your profile",
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
                    title: "settings.preferences".tr(context),
                    subtitle: "App settings and notifications",
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/preferences');
                    },
                  ),
                  // Language Switcher
                  Consumer(
                    builder: (context, ref, child) {
                      final currentLocale = ref.watch(localeProvider);
                      final isTamil = currentLocale.languageCode == 'ta';

                      return _buildSettingsMenuItem(
                        icon: Icons.language,
                        title: "settings.language".tr(context),
                        subtitle: isTamil ? "settings.tamil".tr(context) : "settings.english".tr(context),
                        color: Colors.purple,
                        onTap: () {
                          // Toggle language
                          final newLocale = isTamil ? const Locale('en') : const Locale('ta');
                          ref.read(localeProvider.notifier).setLocale(newLocale);
                          
                          // Force UI rebuild if needed or show confirmation
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppPadding.medium + 4),

                  // Help & Support Option
                  _buildSettingsMenuItem(
                    icon: Icons.help_outline,
                    title: "settings.helpSupport".tr(context),
                    subtitle: "Get help and report issues",
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
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: AppPadding.medium + 4),

                  // Logout Option
                  _buildSettingsMenuItem(
                    icon: Icons.logout_outlined,
                    title: "settings.logout".tr(context),
                    subtitle: "Sign out from your account",
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
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            Text(
              "dashboard.logoutTitle".tr(context),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          "dashboard.logoutMessage".tr(context),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "cancel".tr(context),
              style: const TextStyle(
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
              final authService = ref.read(authRepositoryProvider);
              await authService.signOut();
            },
            child: Text(
              "dashboard.confirmLogout".tr(context),
              style: const TextStyle(
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
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
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
                      style: const TextStyle(
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
                color: color.withValues(alpha: 0.6),
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
                  // Header Block
                  Padding(
                    padding: const EdgeInsets.all(AppPadding.large),
                    child: authState.when(
                      data: (user) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppPadding.medium),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety,
                                    color: AppColors.onPrimary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RescueTN',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'VOLUNTEER',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: AppColors.onAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                PopupMenuButton<VolunteerStatus>(
                                  initialValue: user?.status ?? VolunteerStatus.available,
                                  onSelected: _updateVolunteerStatus,
                                  itemBuilder: (context) => VolunteerStatus.values.map((status) {
                                    return PopupMenuItem(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Icon(status.icon, color: status.color),
                                          const SizedBox(width: 8),
                                          Text("volunteerStatus.${status.name}".tr(context)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (user?.status ?? VolunteerStatus.available).color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          (user?.status ?? VolunteerStatus.available).icon,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "volunteerStatus.${user?.status?.name ?? 'available'}".tr(context),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.settings, color: Colors.white),
                                  onPressed: _showSettingsMenu,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Card
                          allTasksAsync.when(
                            data: (allTasks) {
                              final user = authState.value;
                              final myTasks = allTasks.where((t) {
                                if (user == null) return false;
                                return t.assignedTo == user.uid || t.status == TaskStatus.pending;
                              }).toList();
                              
                              final pending = myTasks.where((t) => t.status == TaskStatus.pending).length;
                              final active = myTasks.where((t) => t.status == TaskStatus.inProgress).length;
                              final done = myTasks.where((t) => t.status == TaskStatus.completed).length;

                              return Container(
                                margin: const EdgeInsets.all(AppPadding.large),
                                padding: const EdgeInsets.all(AppPadding.large),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "dashboard.welcome".tr(context),
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(child: _buildStatCard(
                                          label: "dashboard.pending".tr(context),
                                          count: pending,
                                          color: Colors.orange,
                                          icon: Icons.pending_actions,
                                        )),
                                        const SizedBox(width: 8),
                                        Expanded(child: _buildStatCard(
                                          label: "dashboard.active".tr(context),
                                          count: active,
                                          color: Colors.blue,
                                          icon: Icons.run_circle,
                                        )),
                                        const SizedBox(width: 8),
                                        Expanded(child: _buildStatCard(
                                          label: "dashboard.done".tr(context),
                                          count: done,
                                          color: Colors.green,
                                          icon: Icons.check_circle,
                                        )),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_,__) => const SizedBox.shrink(),
                          ),

                          // Situational Awareness
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                            child: Text(
                              "dashboard.situationalAwareness".tr(context),
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                              children: [
                                _buildAwarenessCard(
                                  title: "dashboard.heatmapTitle".tr(context),
                                  subtitle: "dashboard.heatmapSubtitle".tr(context),
                                  icon: Icons.map,
                                  gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                                  onTap: () => context.go('/heatmap'),
                                ),
                                const SizedBox(width: 16),
                                _buildAwarenessCard(
                                  title: "dashboard.sheltersTitle".tr(context),
                                  subtitle: "dashboard.sheltersSubtitle".tr(context),
                                  icon: Icons.home,
                                  gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
                                  onTap: () => context.go('/shelter-map'),
                                ),
                                const SizedBox(width: 16),
                                _buildAwarenessCard(
                                  title: "dashboard.alertsTitle".tr(context),
                                  subtitle: "dashboard.alertsSubtitle".tr(context),
                                  icon: Icons.notifications,
                                  gradient: const LinearGradient(colors: [Colors.blue, Colors.indigo]),
                                  onTap: () => context.go('/alerts'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          
                          // Task Filter & List
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                            child: _buildFilterChips(context, ref),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          filteredTasksAsync.when(
                            data: (tasks) {
                              if (tasks.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text("tasks.noTasks".tr(context)),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: tasks.length,
                                padding: const EdgeInsets.symmetric(horizontal: AppPadding.large, vertical: 8),
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskCard(task: tasks[index]),
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e,__) => Center(child: Text('Error: $e')),
                          ),
                          
                          const SizedBox(height: 80), // Fab spacing
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    final current = ref.watch(taskFilterProvider);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: TaskFilter.values.map((filter) {
          final isSelected = current == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text("taskFilters.${filter.name}".tr(context).toUpperCase()),
              selected: isSelected,
              onSelected: (val) => ref.read(taskFilterProvider.notifier).state = filter,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}