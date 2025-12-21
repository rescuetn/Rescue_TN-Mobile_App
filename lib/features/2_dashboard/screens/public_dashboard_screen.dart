import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';
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
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
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
                          
                          // Close menu
                          Navigator.pop(context);
                        },
                      );
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


  /// Launch dialer with number
  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('dashboard.callError'.tr(context))),
        );
      }
    }
  }

  /// Show futuristic emergency SOS sheet
  void _showSOSSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
             BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: AppColors.error.withValues(alpha: 0.1),
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.emergency_share, color: AppColors.error, size: 28),
                 ),
                 const SizedBox(width: 12),
                 Text(
                  "dashboard.emergencySOS".tr(context),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "dashboard.whoToCall".tr(context),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Emergency Options
            Row(
              children: [
                Expanded(
                  child: _buildFuturisticEmergencyOption(
                    title: "dashboard.ambulance".tr(context),
                    number: '108',
                    icon: Icons.medical_services_outlined,
                    color: Colors.red,
                    gradientColors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFuturisticEmergencyOption(
                    title: "dashboard.fire".tr(context),
                    number: '101',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.orange,
                    gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFuturisticEmergencyOption(
                    title: "dashboard.police".tr(context),
                    number: '100',
                    icon: Icons.local_police_outlined,
                    color: Colors.blue,
                    gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticEmergencyOption({
    required String title,
    required String number,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _launchDialer(number);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.last.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 14,
                color: AppColors.textPrimary
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
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
              final authService = ref.read(authRepositoryProvider);
              await authService.signOut();
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

  @override
  Widget build(BuildContext context) {
    // Watch the authStateChangesProvider to get live Firebase user data
    final authState = ref.watch(authStateChangesProvider);
    final textTheme = Theme.of(context).textTheme;

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) {
        // Suppress permission errors during logout/auth transitions
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      data: (user) {
        // Extract user name from email or use default
        final email = user?.email ?? '';
        String userName = email.isNotEmpty ? email.split('@').first : 'User';
        if (userName.isNotEmpty) {
          userName = userName.substring(0, 1).toUpperCase() + userName.substring(1);
        }

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 80,
            height: 80,
            child: FloatingActionButton(
              onPressed: _showSOSSheet,
              elevation: 0,
              highlightElevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.red.shade500, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade600.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
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
                                      color: AppColors.onPrimary.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
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
                                  color: AppColors.onPrimary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.settings_outlined),
                                  color: AppColors.onPrimary,
                                  tooltip: 'settings.title'.tr(context),
                                  onPressed: _showSettingsMenu,
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
                                color: AppColors.primary.withValues(alpha: 0.15),
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
                                          color: AppColors.primary.withValues(alpha: 0.4),
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
                                          "dashboard.welcome".tr(context),
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
                                      AppColors.primary.withValues(alpha: 0.08),
                                      AppColors.primary.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
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
                                        "dashboard.howCanWeHelp".tr(context),
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
                                  color: Colors.red.withValues(alpha: 0.4),
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
                                    color: AppColors.onPrimary.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
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
                                        "dashboard.emergencyBannerTitle".tr(context),
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "dashboard.emergencyBannerSubtitle".tr(context),
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.onPrimary.withValues(alpha: 0.95),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.onPrimary.withValues(alpha: 0.2),
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
                                  color: AppColors.primary.withValues(alpha: 0.1),
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
                                "dashboard.quickActions".tr(context),
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
                              title: "dashboard.reportIncident".tr(context),
                              subtitle: "dashboard.reportIncidentSub".tr(context),
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
                              title: "dashboard.findShelter".tr(context),
                              subtitle: "dashboard.findShelterSub".tr(context),
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
                              title: "dashboard.viewAlerts".tr(context),
                              subtitle: "dashboard.viewAlertsSub".tr(context),
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
                              title: "dashboard.personStatus".tr(context),
                              subtitle: "dashboard.personStatusSub".tr(context),
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
                              title: "dashboard.liveHeatmap".tr(context),
                              subtitle: "dashboard.liveHeatmapSub".tr(context),
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
                              title: "dashboard.myPlan".tr(context),
                              subtitle: "dashboard.myPlanSub".tr(context),
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
                                Colors.blue.shade100.withValues(alpha: 0.3),
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
                                      "dashboard.stayPrepared".tr(context),
                                      style: textTheme.titleSmall?.copyWith(
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "dashboard.stayPreparedSubtitle".tr(context),
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
              color: AppColors.textPrimary.withValues(alpha: 0.08),
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
                      color: gradient.colors.first.withValues(alpha: 0.2),
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
                          color: gradient.colors.first.withValues(alpha: 0.4),
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
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
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