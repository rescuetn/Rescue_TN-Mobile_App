import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/6_preparedness/providers/preparedness_plan_provider.dart';
import 'package:rescuetn/models/preparedness_model.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';

class PreparednessPlanScreen extends ConsumerStatefulWidget {
  const PreparednessPlanScreen({super.key});

  @override
  ConsumerState<PreparednessPlanScreen> createState() =>
      _PreparednessPlanScreenState();
}

class _PreparednessPlanScreenState extends ConsumerState<PreparednessPlanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(preparednessPlanProvider);
    final progressAsync = ref.watch(preparednessProgressProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade600,
              Colors.blue.shade500,
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
                child: Row(
                  children: [
                    Hero(
                      tag: 'back_button',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "preparedness.title".tr(context),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "preparedness.subtitle".tr(context),
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: planAsync.when(
                        loading: () => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                                Text(
                                "preparedness.loading".tr(context),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading plan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$err',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        data: (plan) {
                          if (plan.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.checklist,
                                      size: 80, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                    Text(
                                    "preparedness.empty".tr(context),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "preparedness.startCreating".tr(context),
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            );
                          }

                          final essentials = plan
                              .where((i) =>
                                  i.category == PreparednessCategory.essentials)
                              .toList();
                          final documents = plan
                              .where((i) =>
                                  i.category == PreparednessCategory.documents)
                              .toList();
                          final actions = plan
                              .where((i) =>
                                  i.category == PreparednessCategory.actions)
                              .toList();

                          return ListView(
                            padding: const EdgeInsets.all(20.0),
                            children: [
                              // Enhanced Progress Card
                              progressAsync.when(
                                data: (progress) =>
                                    _buildProgressCard(context, progress),
                                loading: () => const SizedBox.shrink(),
                                error: (e, st) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 32),

                              // Checklist Sections
                              _buildCategorySection(
                                "preparedness.essentials".tr(context),
                                essentials,
                                ref,
                                Icons.shopping_bag_rounded,
                                Colors.blue,
                              ),
                              _buildCategorySection(
                                "preparedness.documents".tr(context),
                                documents,
                                ref,
                                Icons.description_rounded,
                                Colors.orange,
                              ),
                              _buildCategorySection(
                                "preparedness.actions".tr(context),
                                actions,
                                ref,
                                Icons.task_alt_rounded,
                                Colors.purple,
                              ),
                              const SizedBox(height: 20),
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

  Widget _buildProgressCard(BuildContext context, double progress) {
    final textTheme = Theme.of(context).textTheme;
    final int percentage = (progress * 100).round();
    Color progressColor =
        Color.lerp(Colors.orange, Colors.green, progress) ?? Colors.green;

    String motivationText;
    IconData motivationIcon;

    if (percentage < 30) {
      motivationText = 'Just getting started! Keep going.';
      motivationIcon = Icons.rocket_launch_rounded;
    } else if (percentage < 70) {
      motivationText = 'Great progress! You\'re halfway there.';
      motivationIcon = Icons.trending_up_rounded;
    } else if (percentage < 100) {
      motivationText = 'Almost ready! Just a few more items.';
      motivationIcon = Icons.star_half_rounded;
    } else {
      motivationText = 'Excellent! You\'re fully prepared.';
      motivationIcon = Icons.verified_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withValues(alpha: 0.1),
            progressColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) =>
                          CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$percentage%',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        'Ready',
                        style: textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          motivationIcon,
                          color: progressColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "preparedness.score".tr(context),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      motivationText,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String title,
    List<PreparednessItem> items,
    WidgetRef ref,
    IconData icon,
    Color accentColor,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final completedCount = items.where((item) => item.isCompleted).length;
    final totalCount = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildChecklistItem(item, ref, accentColor),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChecklistItem(
      PreparednessItem item, WidgetRef ref, Color accentColor) {
    return GestureDetector(
      onTap: () {
        ref
            .read(preparednessControllerProvider.notifier)
            .toggleItemStatus(item.id, item.isCompleted);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color:
              item.isCompleted ? accentColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isCompleted
                ? accentColor.withValues(alpha: 0.4)
                : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: item.isCompleted
                  ? accentColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.isCompleted ? accentColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isCompleted ? accentColor : Colors.grey.shade300,
                  width: 2.5,
                ),
                boxShadow: item.isCompleted
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: item.isCompleted
                          ? Colors.grey.shade600
                          : Colors.black87,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.isCompleted
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (item.isCompleted)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
