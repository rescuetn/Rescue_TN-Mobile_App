import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/features/5_task_management/widgets/task_card.dart';
import 'package:rescuetn/models/user_model.dart';

class VolunteerDashboardScreen extends ConsumerStatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  ConsumerState<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends ConsumerState<VolunteerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = ref.watch(userStateProvider);
    // Watch the new filtered provider to get the list of tasks to display.
    final tasks = ref.watch(filteredTaskListProvider);
    final textTheme = Theme.of(context).textTheme;

    // Extract user name from email or use default
    String userName = user?.email?.split('@').first ?? 'Volunteer';
    userName = userName.substring(0, 1).toUpperCase() + userName.substring(1);

    // Get task statistics
    final allTasks = ref.watch(taskListProvider);
    final pendingCount = allTasks.where((t) => t.status == 'pending').length;
    final activeCount = allTasks.where((t) => t.status == 'active').length;
    final completedCount = allTasks.where((t) => t.status == 'completed').length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade700,
              Colors.red.shade600,
              AppColors.background,
            ],
            stops: const [0.0, 0.25, 0.25],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo/App Name with badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppPadding.small),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              color: AppColors.onPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppPadding.small),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RescueTN',
                                style: textTheme.titleLarge?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppPadding.small,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                                ),
                                child: Text(
                                  'VOLUNTEER',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.onAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
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
                          color: AppColors.onPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.person_outline),
                          color: AppColors.onPrimary,
                          tooltip: 'Profile',
                          onPressed: () => context.go('/profile'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Welcome Card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppPadding.medium,
                    vertical: AppPadding.small,
                  ),
                  padding: const EdgeInsets.all(AppPadding.large),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppPadding.medium + AppPadding.small),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppPadding.medium),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade400, Colors.red.shade600],
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism,
                              color: AppColors.onPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppPadding.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPadding.medium + AppPadding.small),

                      // Statistics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              label: 'Pending',
                              count: pendingCount,
                              color: Colors.orange,
                              icon: Icons.pending_actions,
                            ),
                          ),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: _buildStatCard(
                              label: 'Active',
                              count: activeCount,
                              color: Colors.blue,
                              icon: Icons.work_outline,
                            ),
                          ),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: _buildStatCard(
                              label: 'Done',
                              count: completedCount,
                              color: Colors.green,
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppPadding.medium),

                // Filter Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppPadding.small),
                      Text(
                        'Filter Tasks',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.small),

                // Filter Chips
                _buildFilterChips(context, ref),

                const SizedBox(height: AppPadding.medium),

                // Task List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Assigned Tasks',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.small + 4,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppBorderRadius.small + 4),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppPadding.small),

                // Task List Section
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppPadding.large),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.task_alt,
                            size: 64,
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: AppPadding.large),
                        Text(
                          'No tasks found',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppPadding.medium,
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
        vertical: AppPadding.small + 4,
        horizontal: AppPadding.small,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
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
              filterColor = Colors.orange;
              break;
            case TaskFilter.inProgress:
              filterIcon = Icons.work;
              filterColor = Colors.blue;
              break;
            case TaskFilter.completed:
              filterIcon = Icons.check_circle;
              filterColor = Colors.green;
              break;
            default:
              filterIcon = Icons.filter_list;
              filterColor = AppColors.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppPadding.small),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filterIcon,
                    size: 16,
                    color: isSelected ? AppColors.onPrimary : filterColor,
                  ),
                  const SizedBox(width: AppPadding.small),
                  Text(
                    filter.name[0].toUpperCase() + filter.name.substring(1),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
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
              backgroundColor: AppColors.surface,
              selectedColor: filterColor,
              checkmarkColor: AppColors.onPrimary,
              side: BorderSide(
                color: isSelected ? filterColor : AppColors.textSecondary.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.medium,
                vertical: AppPadding.small,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}