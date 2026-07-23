import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/meal_item_tile.dart';
import '../widgets/calorie_progress_ring.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/edit_item_sheet.dart';
import 'create_meal_plan_screen.dart';
import 'meal_plan_stats_screen.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';

/// Screen chi tiết meal plan
class MealPlanDetailScreen extends StatefulWidget {
  const MealPlanDetailScreen({
    super.key,
    required this.planId,
    this.initialDate,
  });

  final String planId;
  final DateTime? initialDate;

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
                  onSelected: (value) =>
                      _handleMenuAction(context, value, plan),
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
                    if (plan.isActive)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.archive_outlined,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Kết thúc',
                              style: TextStyle(color: Colors.red),
                            ),
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
          Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
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

  Widget _buildContent(
    BuildContext context,
    MealPlanDetail plan,
    MealPlanProvider provider,
  ) {
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
                  onMarkItemDone: (item) =>
                      _toggleItemCompletion(context, item),
                  onConvertToLog: (item) => _convertItemToLog(context, item),
                  onEditItem: (item) => _editItem(context, item),
                  onDeleteItem: (item) => _deleteItemFromPlan(context, item),
                  onSkipItem: (item) => _skipItem(context, item),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
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
    final durationDays =
        plan.startDate != null &&
            plan.endDate != null &&
            !plan.endDate!.isBefore(plan.startDate!)
        ? plan.endDate!.difference(plan.startDate!).inDays + 1
        : 1;
    final calorieTarget = (plan.targetCalories ?? 2000) * durationDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dinh dưỡng tuần này',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            MacroProgressBar(
              label: 'KCAL',
              current: plan.totalCalories,
              target: calorieTarget,
              unit: 'kcal',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            MacroProgressBar(
              label: 'PROTEIN',
              current: plan.totalProteinG,
              target: plan.targetProtein ?? 840,
              unit: 'g',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            MacroProgressBar(
              label: 'CARBS',
              current: plan.totalCarbsG,
              target: plan.targetCarbs ?? 1750,
              unit: 'g',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            MacroProgressBar(
              label: 'FAT',
              current: plan.totalFatG,
              target: plan.targetFat ?? 420,
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
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }

  void _addItem(BuildContext context, [MealType? mealType]) {
    HapticFeedback.lightImpact();

    final selectedMealType = mealType ?? MealType.snack;

    AddItemSheet.show(
      context: context,
      planId: widget.planId,
      mealType: selectedMealType,
      scheduledTime: DateTime.now(),
    ).then((request) async {
      if (request != null && context.mounted) {
        final provider = context.read<MealPlanProvider>();
        final item = await provider.addItem(widget.planId, request);

        if (context.mounted) {
          if (item != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm món vào kế hoạch')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.error ?? 'Không thể thêm món')),
            );
          }
        }
      }
    });
  }

  void _openItemDetail(BuildContext context, MealPlanItemDetail item) {
    // Navigate based on item type (food or recipe)
    if (item.recipeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: item.recipeId!),
        ),
      );
    } else if (item.foodId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(foodId: item.foodId!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin chi tiết')),
      );
    }
  }

  void _toggleItemCompletion(
    BuildContext context,
    MealPlanItemDetail item,
  ) async {
    HapticFeedback.mediumImpact();
    final provider = context.read<MealPlanProvider>();

    final success = await provider.toggleItemCompletion(
      item.id,
      !item.isDone,
      planId: widget.planId,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.isDone
                  ? 'Đã hủy đánh dấu ăn "${item.displayName}"'
                  : 'Đã hoàn thành "${item.displayName}"',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiMessageTranslator.translate(
                provider.error ?? 'Không thể cập nhật',
              ),
            ),
          ),
        );
      }
    }
  }

  void _editItem(BuildContext context, MealPlanItemDetail item) {
    EditItemSheet.show(
      context: context,
      planId: widget.planId,
      item: item,
      onItemUpdated: () {
        context.read<MealPlanProvider>().loadPlanDetail(widget.planId);
      },
    );
  }

  void _convertItemToLog(BuildContext context, MealPlanItemDetail item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi nhận ăn uống'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chuyển "${item.displayName}" thành bản ghi ăn uống thực tế?'),
            const SizedBox(height: 8),
            Text(
              'Hành động này sẽ ghi nhận bữa ăn này vào lịch sử dinh dưỡng của bạn.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ghi nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<MealPlanProvider>();
      final request = ConvertToLogRequest(
        quantityG: null, // Use default quantity from plan item
      );

      final result = await provider.convertItemToLog(
        widget.planId,
        item.id,
        request,
      );

      if (context.mounted) {
        if (result?.success == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã ghi nhận "${item.displayName}"')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result?.message ?? provider.error ?? 'Không thể ghi nhận',
              ),
            ),
          );
        }
      }
    }
  }

  void _deleteItemFromPlan(
    BuildContext context,
    MealPlanItemDetail item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa món'),
        content: Text(
          'Bạn có chắc muốn xóa "${item.displayName}" khỏi kế hoạch?',
        ),
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
      final provider = context.read<MealPlanProvider>();
      final success = await provider.deleteItem(widget.planId, item.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Đã xóa món' : 'Không thể xóa món')),
        );
      }
    }
  }

  void _skipItem(BuildContext context, MealPlanItemDetail item) async {
    HapticFeedback.lightImpact();
    final provider = context.read<MealPlanProvider>();

    final updatedItem = await provider.skipItem(widget.planId, item.id);

    if (context.mounted) {
      if (updatedItem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã bỏ qua "${item.displayName}"')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Không thể cập nhật')),
        );
      }
    }
  }

  void _logAllMeal(BuildContext context, List<MealPlanItemDetail> items) async {
    HapticFeedback.mediumImpact();
    final provider = context.read<MealPlanProvider>();
    final pendingCount = items.where((item) => !item.isDone).length;
    final completedCount = await provider.completeItems(
      items,
      planId: widget.planId,
    );

    if (context.mounted) {
      final failedCount = pendingCount - completedCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedCount == 0
                ? 'Đã ghi nhận $completedCount món'
                : 'Đã ghi nhận $completedCount món, $failedCount món chưa thành công',
          ),
        ),
      );
    }
  }

  void _editPlan(BuildContext context) {
    final plan = context.read<MealPlanProvider>().currentPlan;
    if (plan == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMealPlanScreen(existingPlan: plan),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        // Reload plan detail after edit
        context.read<MealPlanProvider>().loadPlanDetail(widget.planId);
      }
    });
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    MealPlanDetail plan,
  ) {
    switch (action) {
      case 'duplicate':
        _duplicatePlan(context, plan);
        break;
      case 'delete':
        _deletePlan(context, plan);
        break;
    }
  }

  void _duplicatePlan(BuildContext context, MealPlanDetail plan) async {
    DateTime newStartDate = DateTime.now();
    DateTime? newEndDate;

    // Calculate end date based on plan type
    if (plan.endDate != null && plan.startDate != null) {
      final duration = plan.endDate!.difference(plan.startDate!);
      newEndDate = newStartDate.add(duration);
    } else {
      newEndDate = newStartDate.add(const Duration(days: 6));
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nhân bản kế hoạch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tạo bản sao của "${plan.title}"?'),
              const SizedBox(height: 16),
              const Text(
                'Chọn ngày bắt đầu:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: newStartDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setDialogState(() {
                            newStartDate = date;
                            if (plan.endDate != null &&
                                plan.startDate != null) {
                              final duration = plan.endDate!.difference(
                                plan.startDate!,
                              );
                              newEndDate = newStartDate.add(duration);
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_formatDate(newStartDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Đến ngày: ${newEndDate != null ? _formatDate(newEndDate!) : "..."}',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nhân bản'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<MealPlanProvider>();
      final request = DuplicatePlanRequest(
        newStartDate: newStartDate,
        newEndDate: newEndDate,
      );

      final newPlan = await provider.duplicatePlan(plan.id, request);

      if (context.mounted) {
        if (newPlan != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã nhân bản thành "${newPlan.title}"'),
              action: SnackBarAction(
                label: 'Xem',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealPlanDetailScreen(planId: newPlan.id),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Không thể nhân bản kế hoạch'),
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _deletePlan(BuildContext context, MealPlanDetail plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc kế hoạch'),
        content: Text(
          'Kế hoạch "${plan.title}" sẽ được chuyển vào nhóm đã kết thúc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<MealPlanProvider>().deletePlan(
        plan.id,
      );
      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể kết thúc kế hoạch')),
          );
        }
      }
    }
  }

  void _comparePlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealPlanStatsScreen()),
    );
  }
}
