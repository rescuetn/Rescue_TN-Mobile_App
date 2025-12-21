import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/7_alerts/providers/alert_provider.dart';
import 'package:rescuetn/features/7_alerts/widgets/alert_card_widget.dart';
import 'package:rescuetn/models/alert_model.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live stream
    final allAlertsAsync = ref.watch(alertsStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade700,
              Colors.red.shade600,
              Colors.red.shade500,
              AppColors.background,
            ],
            stops: const [0.0, 0.15, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Back Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "alerts.title".tr(context),
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Live alert count from Firebase
                              allAlertsAsync.when(
                                data: (alerts) => Text(
                                  '${alerts.length} ${"alerts.active".tr(context)}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                loading: () => Text(
                                  "alerts.loading".tr(context),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                error: (e, s) => Text(
                                  "alerts.error".tr(context),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.red.shade700,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: "alerts.tabAll".tr(context)),
                    Tab(text: "alerts.tabSevere".tr(context)),
                    Tab(text: "alerts.tabWarning".tr(context)),
                    Tab(text: "alerts.tabInfo".tr(context)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Bar View Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: allAlertsAsync.when(
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
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "alerts.failed".tr(context),
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        data: (allAlerts) {
                          return TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAlertList(allAlerts, AlertFilter.all),
                              _buildAlertList(allAlerts, AlertFilter.severe),
                              _buildAlertList(allAlerts, AlertFilter.warning),
                              _buildAlertList(allAlerts, AlertFilter.info),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertList(List<Alert> allAlerts, AlertFilter filter) {
    // Filter the list based on the tab category
    List<Alert> filteredAlerts;
    if (filter == AlertFilter.all) {
      filteredAlerts = allAlerts;
    } else {
      final correspondingLevel = AlertLevel.values.firstWhere(
            (level) => level.name == filter.name,
        orElse: () => AlertLevel.info,
      );
      filteredAlerts = allAlerts.where((a) => a.level == correspondingLevel).toList();
    }

    if (filteredAlerts.isEmpty) {
      return _buildEmptyState(filter);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(alertsStreamProvider.future),
      color: Colors.red.shade600,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredAlerts.length,
        itemBuilder: (context, index) {
          final alert = filteredAlerts[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: AlertCard(alert: alert),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 16),
      ),
    );
  }

  Widget _buildEmptyState(AlertFilter filter) {
    String title;
    String message;
    IconData icon;
    Color color;

    switch (filter) {
      case AlertFilter.severe:
        title = "alerts.emptySevereTitle".tr(context);
        message = "alerts.emptySevereMessage".tr(context);
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case AlertFilter.warning:
        title = "alerts.emptyWarningTitle".tr(context);
        message = "alerts.emptyWarningMessage".tr(context);
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case AlertFilter.info:
        title = "alerts.emptyInfoTitle".tr(context);
        message = "alerts.emptyInfoMessage".tr(context);
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
      case AlertFilter.all:
        title = "alerts.emptyAllTitle".tr(context);
        message = "alerts.emptyAllMessage".tr(context);
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: color,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}