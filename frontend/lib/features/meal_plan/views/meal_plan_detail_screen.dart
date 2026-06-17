import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/meal_item_tile.dart';
import '../widgets/calorie_progress_ring.dart';

/// Screen chi tiết meal plan
class MealPlanDetailScreen extends StatefulWidget {
  const MealPlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  State<MealPlanDetailScreen> createState() => _MealPlanDetailScreenState();
}

class _MealPlanDetailScreenState extends State<MealPlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlanProvider>().loadPlanDetail(widget.planId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealPlanProvider>(
      builder: (context, provider, child) {
        final plan = provider.currentPlan;

        return Scaffold(
          appBar: AppBar(
            title: Text(plan?.title ?? 'Chi tiết kế hoạch'),
            actions: [
              if (plan != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editPlan(context),
                  tooltip: 'Sửa',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, value, plan),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Nhân bản'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: provider.isLoadingDetail
              ? const Center(child: CircularProgressIndicator())
              : plan == null
                  ? _buildEmptyState(context)
                  : _buildContent(context, plan, provider),
          floatingActionButton: plan != null
              ? FloatingActionButton(
                  onPressed: () => _addItem(context),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy kế hoạch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MealPlanDetail plan, MealPlanProvider provider) {
    // Group items by meal type
    final grouped = <MealType, List<MealPlanItemDetail>>{};
    for (final item in plan.items) {
      final mealType = MealType.fromString(item.mealType);
      grouped.putIfAbsent(mealType, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPlanDetail(widget.planId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress summary card
          _buildProgressCard(plan),
          const SizedBox(height: 24),

          // Macro progress
          _buildMacroProgress(plan),
          const SizedBox(height: 24),

          // Actions
          _buildActionButtons(context, plan),
          const SizedBox(height: 24),

          // Meal sections
          ...MealType.values.map((mealType) {
            final items = grouped[mealType] ?? [];
            if (items.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDayHeader(mealType.labelVi),
                PlannedMealCard(
                  mealType: mealType,
                  items: items,
                  onAddItem: () => _addItem(context, mealType),
                  onTapItem: (item) => _openItemDetail(context, item),
                  onLogAll: items.any((i) => !i.isDone)
                      ? () => _logAllMeal(context, items)
                      : null,
                ),
                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 80), // FAB spacing
        ],
      ),
    );
  }

  Widget _buildProgressCard(MealPlanDetail plan) {
    final progress = plan.completionPercent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.completedCount}/${plan.totalCount} bữa hoàn thành',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                CalorieProgressRing(
                  current: plan.completedCount,
                  target: plan.totalCount > 0 ? plan.totalCount : 1,
                  size: 70,
                  strokeWidth: 8,
                  label: 'bữa',
                  showPercent: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.progressBackground,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroProgress(MealPlanDetail plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Macros tuần này',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            MacroProgressBar(
              label: 'KCAL',
              current: plan.totalCalories,
              target: plan.targetCalories ?? 14000,
              unit: 'kcal',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            MacroProgressBar(
              label: 'PROTEIN',
              current: plan.totalProteinG,
              target: plan.targetProtein ?? 500,
              unit: 'g',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            MacroProgressBar(
              label: 'CARBS',
              current: plan.totalCarbsG,
              target: plan.targetCarbs ?? 1100,
              unit: 'g',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            MacroProgressBar(
              label: 'FAT',
              current: plan.totalFatG,
              target: plan.targetFat ?? 450,
              unit: 'g',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MealPlanDetail plan) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _setReminders(context, plan),
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Nhắc nhở'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _comparePlan(context),
            icon: const Icon(Icons.compare_arrows),
            label: const Text('So sánh'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _duplicatePlan(context, plan),
            icon: const Icon(Icons.copy),
            label: const Text('Sao chép'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const Expanded(
            child: Divider(indent: 12),
          ),
        ],
      ),
    );
  }

  void _addItem(BuildContext context, [MealType? mealType]) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thêm bữa ${mealType?.labelVi ?? "ăn"}')),
    );
  }

  void _openItemDetail(BuildContext context, MealPlanItemDetail item) {
    // TODO: Navigate to food/recipe detail
  }

  void _logAllMeal(BuildContext context, List<MealPlanItemDetail> items) async {
    HapticFeedback.mediumImpact();
    final provider = context.read<MealPlanProvider>();

    for (final item in items.where((i) => !i.isDone)) {
      await provider.markItemDone(widget.planId, item.id);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã log ${items.length} món')),
      );
    }
  }

  void _editPlan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sửa kế hoạch')),
    );
  }

  void _handleMenuAction(BuildContext context, String action, MealPlanDetail plan) {
    switch (action) {
      case 'duplicate':
        _duplicatePlan(context, plan);
        break;
      case 'delete':
        _deletePlan(context, plan);
        break;
    }
  }

  void _duplicatePlan(BuildContext context, MealPlanDetail plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nhân bản "${plan.title}"')),
    );
  }

  void _deletePlan(BuildContext context, MealPlanDetail plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa kế hoạch'),
        content: Text('Bạn có chắc muốn xóa "${plan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<MealPlanProvider>().deletePlan(plan.id);
      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể xóa kế hoạch')),
          );
        }
      }
    }
  }

  void _setReminders(BuildContext context, MealPlanDetail plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cài đặt nhắc nhở')),
    );
  }

  void _comparePlan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('So sánh kế hoạch')),
    );
  }
}
