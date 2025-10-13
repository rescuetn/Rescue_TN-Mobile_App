import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/features/2_dashboard/widgets/quick_action_card.dart';
import 'package:rescuetn/models/user_model.dart';

/// The main dashboard for users logged in with the 'Public' role.
/// It provides quick access to the most critical features of the app.
class PublicDashboardScreen extends ConsumerStatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  ConsumerState<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends ConsumerState<PublicDashboardScreen>
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
    // Watch the user state provider to get the current user's data.
    final AppUser? user = ref.watch(userStateProvider);
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    // Extract user name from email or use default
    String userName = user?.email?.split('@').first ?? 'User';
    userName = userName.substring(0, 1).toUpperCase() + userName.substring(1);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              AppColors.background,
            ],
            stops: const [0.0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo/App Name
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
                            Text(
                              'RescueTN',
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
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
                ),

                // Welcome Card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppPadding.medium,
                      vertical: AppPadding.small,
                    ),
                    padding: const EdgeInsets.all(AppPadding.large),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.onPrimary.withOpacity(0.95),
                          AppColors.onPrimary.withOpacity(0.85),
                        ],
                      ),
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
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                ),
                                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                              ),
                              child: const Icon(
                                Icons.waving_hand,
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
                        const SizedBox(height: AppPadding.medium),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.medium),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppPadding.small),
                              Expanded(
                                child: Text(
                                  'How can we help you today?',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
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

                // Emergency Banner
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppPadding.medium,
                      vertical: AppPadding.medium,
                    ),
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.large),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppPadding.small),
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.small),
                          ),
                          child: const Icon(
                            Icons.phone_in_talk,
                            color: AppColors.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppPadding.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Hotline',
                                style: textTheme.titleSmall?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tap to call 108',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.onPrimary.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.onPrimary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                // Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppPadding.large,
                      AppPadding.medium,
                      AppPadding.large,
                      AppPadding.medium,
                    ),
                    child: Text(
                      'Quick Actions',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // Quick Action Cards Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: AppPadding.medium,
                      mainAxisSpacing: AppPadding.medium,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildEnhancedActionCard(
                        context: context,
                        title: 'Report Incident',
                        subtitle: 'Alert authorities',
                        icon: Icons.warning_amber_rounded,
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        ),
                        onTap: () => context.go('/report-incident'),
                      ),
                      _buildEnhancedActionCard(
                        context: context,
                        title: 'Find Shelter',
                        subtitle: 'Safe locations',
                        icon: Icons.maps_home_work_rounded,
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        onTap: () => context.go('/shelter-map'),
                      ),
                      _buildEnhancedActionCard(
                        context: context,
                        title: 'View Alerts',
                        subtitle: 'Stay informed',
                        icon: Icons.notifications_active,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        onTap: () => context.go('/alerts'),
                      ),
                      _buildEnhancedActionCard(
                        context: context,
                        title: 'Person Status',
                        subtitle: 'Safe/Missing',
                        icon: Icons.family_restroom,
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                        onTap: () => context.go('/person-registry'),
                      ),
                    ]),
                  ),
                ),

                // Bottom Spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppPadding.large),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppPadding.medium + AppPadding.small),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppPadding.medium + AppPadding.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.onPrimary,
                      size: 28,
                    ),
                  ),
                  // Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}