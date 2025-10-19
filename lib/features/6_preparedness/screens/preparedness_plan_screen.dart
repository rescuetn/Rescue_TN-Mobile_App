import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/6_preparedness/providers/preparedness_plan_provider.dart';
import 'package:rescuetn/models/preparedness_model.dart';

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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
    final planAsync = ref.watch(preparednessPlanProvider);
    final progressAsync = ref.watch(preparednessProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preparedness Plan'),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (plan) {
          if (plan.isEmpty) {
            return const Center(child: Text('No preparedness plan found.'));
          }
          final essentials = plan
              .where((i) => i.category == PreparednessCategory.essentials)
              .toList();
          final documents = plan
              .where((i) => i.category == PreparednessCategory.documents)
              .toList();
          final actions = plan
              .where((i) => i.category == PreparednessCategory.actions)
              .toList();

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Enhanced Progress Card ---
                  progressAsync.when(
                    data: (progress) => _buildProgressCard(context, progress),
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) =>
                    const Text('Could not calculate progress.'),
                  ),
                  const SizedBox(height: 24),

                  // --- Checklist Sections ---
                  _buildCategorySection('Essentials', essentials, ref),
                  _buildCategorySection('Documents', documents, ref),
                  _buildCategorySection('Actions', actions, ref),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, double progress) {
    final textTheme = Theme.of(context).textTheme;
    final int percentage = (progress * 100).round();
    Color progressColor =
        Color.lerp(Colors.orange, Colors.green, progress) ?? Colors.green;

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) =>
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: progressColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                ),
              ),
              Text(
                '$percentage%',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppPadding.large),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Readiness Score',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete all items to be fully prepared for an emergency.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      String title, List<PreparednessItem> items, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((item) => _buildChecklistItem(item, ref)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChecklistItem(PreparednessItem item, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () {
          ref
              .read(preparednessControllerProvider.notifier)
              .toggleItemStatus(item.id, item.isCompleted);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: item.isCompleted
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isCompleted
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.isCompleted ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isCompleted
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
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
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

