import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/features/5_task_management/widgets/task_card.dart';
import 'package:rescuetn/models/task_model.dart';

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
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live providers for auth, filtered tasks, and all tasks
    final authState = ref.watch(authStateChangesProvider);
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final allTasksAsync = ref.watch(tasksStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade700,
              Colors.red.shade600,
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.25, 0.25],
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
                  // Custom App Bar
                  Padding(
                    padding: const EdgeInsets.all(AppPadding.large),
                    child: authState.when(
                      data: (user) {
                        // Extract user name from email or use default
                        String userName = user?.email?.split('@').first ?? 'Volunteer';
                        if (userName.isNotEmpty) {
                          userName = userName.substring(0, 1).toUpperCase() + userName.substring(1);
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo/App Name with badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppPadding.small + 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.onPrimary.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety,
                                    color: AppColors.onPrimary,
                                    size: 26,
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
                                        fontSize: 22,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppPadding.small + 2,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 4,
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
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Profile Button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.onPrimary.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.person_outline),
                                color: AppColors.onPrimary,
                                tooltip: 'Profile',
                                onPressed: () => context.go('/profile'),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const Text('Error loading user', style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  // Welcome Card with Statistics
                  allTasksAsync.when(
                    data: (allTasks) {
                      final pendingCount = allTasks.where((t) => t.status == TaskStatus.pending).length;
                      final activeCount = allTasks.where((t) => t.status == TaskStatus.inProgress || t.status == TaskStatus.accepted).length;
                      final completedCount = allTasks.where((t) => t.status == TaskStatus.completed).length;

                      // Get user name
                      final userName = authState.value?.email?.split('@').first ?? 'Volunteer';
                      final formattedUserName = userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase() + userName.substring(1)
                          : 'Volunteer';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppPadding.large,
                          vertical: AppPadding.small,
                        ),
                        padding: const EdgeInsets.all(AppPadding.large),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppPadding.medium + 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.red.shade500, Colors.red.shade700],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.volunteer_activism,
                                    color: AppColors.onPrimary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium + 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedUserName,
                                        style: textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          fontSize: 24,
                                          letterSpacing: 0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppPadding.large),

                            // Statistics Row
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
                                const SizedBox(width: AppPadding.medium),
                                Expanded(
                                  child: _buildStatCard(
                                    label: 'Active',
                                    count: activeCount,
                                    color: Colors.blue.shade600,
                                    icon: Icons.work_outline,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.medium),
                                Expanded(
                                  child: _buildStatCard(
                                    label: 'Done',
                                    count: completedCount,
                                    color: Colors.green.shade600,
                                    icon: Icons.check_circle_outline,
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
                      padding: const EdgeInsets.all(AppPadding.large),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (e, s) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppPadding.large, vertical: AppPadding.small),
                      padding: const EdgeInsets.all(AppPadding.large),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('Error loading stats', style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppPadding.large),

                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.filter_list,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppPadding.medium),
                        Text(
                          'Filter Tasks',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.medium),

                  // Filter Chips
                  _buildFilterChips(context, ref),

                  const SizedBox(height: AppPadding.large),

                  // Task List Header
                  filteredTasksAsync.when(
                    data: (tasks) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.assignment,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppPadding.medium),
                              Text(
                                'Assigned Tasks',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                              vertical: AppPadding.small,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade100,
                                  Colors.red.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '${tasks.length}',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

                  // Live Task List Section
                  Expanded(
                    child: filteredTasksAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (err, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppPadding.medium),
                            Text(
                              'Failed to load tasks',
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppPadding.small),
                            Text(
                              err.toString(),
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
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
                              padding: const EdgeInsets.all(AppPadding.xLarge),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt,
                                size: 72,
                                color: Colors.red.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: AppPadding.large),
                            Text(
                              'No tasks found',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: AppPadding.small),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.xLarge,
                              ),
                              child: Text(
                                'No tasks match the current filter. Try selecting a different filter.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.all(AppPadding.large),
                        physics: const BouncingScrollPhysics(),
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
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.symmetric(
        vertical: AppPadding.medium,
        horizontal: AppPadding.small,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium + 2),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// A helper widget to build the row of filter chips.
  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    // Watch the filter provider to know which chip is currently selected.
    final currentFilter = ref.watch(taskFilterProvider);

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
        physics: const BouncingScrollPhysics(),
        children: TaskFilter.values.map((filter) {
          final isSelected = filter == currentFilter;

          // Get appropriate icon and color for each filter
          IconData filterIcon;
          Color filterColor;
          switch (filter) {
            case TaskFilter.all:
              filterIcon = Icons.apps;
              filterColor = AppColors.primary;
              break;
            case TaskFilter.pending:
              filterIcon = Icons.pending_actions;
              filterColor = Colors.orange.shade600;
              break;
            case TaskFilter.inProgress:
              filterIcon = Icons.work;
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
            padding: const EdgeInsets.only(right: AppPadding.medium),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filterIcon,
                    size: 18,
                    color: isSelected ? AppColors.onPrimary : filterColor,
                  ),
                  const SizedBox(width: AppPadding.small + 2),
                  Text(
                    filter.name[0].toUpperCase() + filter.name.substring(1),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // When a chip is tapped, update the state of the filter provider.
                  ref.read(taskFilterProvider.notifier).state = filter;
                }
              },
              backgroundColor: Colors.white,
              selectedColor: filterColor,
              checkmarkColor: AppColors.onPrimary,
              side: BorderSide(
                color: isSelected ? filterColor : AppColors.textSecondary.withOpacity(0.2),
                width: isSelected ? 2 : 1.5,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.medium + 2,
                vertical: AppPadding.small + 2,
              ),
              elevation: isSelected ? 4 : 0,
              shadowColor: filterColor.withOpacity(0.3),
            ),
          );
        }).toList(),
      ),
    );
  }
}