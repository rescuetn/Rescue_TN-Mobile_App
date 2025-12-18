import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _makeEmergencyCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '108');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to make call. Please dial 108 manually.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authStateChangesProvider to get live Firebase user data
    final authState = ref.watch(authStateChangesProvider);
    final textTheme = Theme.of(context).textTheme;

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (user) {
        // Extract user name from email or use default
        final email = user?.email ?? '';
        String userName = email.isNotEmpty ? email.split('@').first : 'User';
        if (userName.isNotEmpty) {
          userName = userName.substring(0, 1).toUpperCase() + userName.substring(1);
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
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
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Custom App Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppPadding.large),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo/App Name
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
                                  Text(
                                    'RescueTN',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      letterSpacing: 0.5,
                                    ),
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
                          ),
                        ),
                      ),

                      // Welcome Card
                      SliverToBoxAdapter(
                        child: Container(
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
                                color: AppColors.primary.withOpacity(0.15),
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
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primary, AppColors.accent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.large),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.waving_hand,
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
                                          userName,
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
                              Container(
                                padding: const EdgeInsets.all(AppPadding.medium + 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.08),
                                      AppColors.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppPadding.medium),
                                    Expanded(
                                      child: Text(
                                        'How can we help you today?',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
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
                        child: GestureDetector(
                          onTap: _makeEmergencyCall,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppPadding.large,
                              vertical: AppPadding.large,
                            ),
                            padding: const EdgeInsets.all(AppPadding.large),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade500,
                                  Colors.red.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.large),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppPadding.medium),
                                  decoration: BoxDecoration(
                                    color: AppColors.onPrimary.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.phone_in_talk,
                                    color: AppColors.onPrimary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.large),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Emergency Hotline',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tap to call 108',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.onPrimary.withOpacity(0.95),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.onPrimary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.onPrimary,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
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
                            AppPadding.large,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.bolt,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppPadding.medium),
                              Text(
                                'Quick Actions',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Quick Action Cards Grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: AppPadding.medium + 4,
                            mainAxisSpacing: AppPadding.medium + 4,
                          ),
                          delegate: SliverChildListDelegate([
                            _buildEnhancedActionCard(
                              context: context,
                              title: 'Report Incident',
                              subtitle: 'Alert authorities',
                              icon: Icons.warning_amber_rounded,
                              gradient: LinearGradient(
                                colors: [Colors.red.shade400, Colors.red.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => context.go('/person-registry'),
                            ),
                            _buildEnhancedActionCard(
                              context: context,
                              title: 'Live Heatmap',
                              subtitle: 'Disaster hotspots',
                              icon: Icons.local_fire_department,
                              gradient: LinearGradient(
                                colors: [Colors.amber.shade600, Colors.orange.shade800],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => context.go('/heatmap'),
                            ),
                            _buildEnhancedActionCard(
                              context: context,
                              title: 'My Plan',
                              subtitle: 'Be prepared',
                              icon: Icons.checklist_rtl_rounded,
                              gradient: LinearGradient(
                                colors: [Colors.teal.shade400, Colors.teal.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => context.go('/preparedness-plan'),
                            ),
                          ]),
                        ),
                      ),

                      // Information Card
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(AppPadding.large),
                          padding: const EdgeInsets.all(AppPadding.large),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppPadding.medium),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                ),
                                child: Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppPadding.medium + 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stay Prepared',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Keep emergency contacts saved and your phone charged.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.blue.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Spacing
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom + AppPadding.large,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient circle
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppPadding.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppPadding.medium + 2),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium + 2),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.onPrimary,
                      size: 32,
                    ),
                  ),
                  // Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
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