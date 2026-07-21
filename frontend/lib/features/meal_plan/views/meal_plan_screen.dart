import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/calorie_progress_ring.dart';
import '../widgets/meal_item_tile.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/edit_item_sheet.dart';
import 'meal_plan_detail_screen.dart';
import 'create_meal_plan_screen.dart';
import 'meal_plan_stats_screen.dart';
import 'meal_plan_calendar_screen.dart';

/// Filter enum for history tab
enum PlanFilter { all, active, completed }

/// Main screen cho Meal Plan - kết hợp list và today dashboard
/// Inspired by Lose It! and MyFitnessPal design
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlanProvider>().loadAllForHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch ăn uống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _openCalendar(context),
            tooltip: 'Lịch kế hoạch',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _openStats(context),
            tooltip: 'Thống kê',
          ),
        ],
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.plans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return _TodayTab(provider: provider);
        },
      ),
    );
  }

  void _openCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealPlanCalendarScreen()),
    );
  }

  void _openStats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealPlanStatsScreen()),
    );
  }
}

/// Màn tổng quan chung: hôm nay + các kế hoạch đã tạo.
class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.provider});

  final MealPlanProvider provider;

  @override
  Widget build(BuildContext context) {
    final dashboard = provider.todayDashboard;
    final streaks = provider.streaks;

    return RefreshIndicator(
      onRefresh: () => provider.loadAllForHome(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.error != null) ...[
            _buildErrorBanner(context),
            const SizedBox(height: 16),
          ],

          // Header with streak
          if (streaks != null && streaks.currentStreak > 0) ...[
            StreakWidget(
              currentStreak: streaks.currentStreak,
              longestStreak: streaks.longestStreak,
            ),
            const SizedBox(height: 16),
          ],

          // Calories card
          TodayCaloriesCard(
            current: provider.todayActualCalories,
            target: provider.todayTargetCalories,
            protein: dashboard?.actualProtein ?? 0,
            proteinTarget: dashboard?.plannedProtein ?? 120,
            carbs: dashboard?.actualCarbs ?? 0,
            carbsTarget: dashboard?.plannedCarbs ?? 200,
            fat: dashboard?.actualFat ?? 0,
            fatTarget: dashboard?.plannedFat ?? 60,
            completedMeals: dashboard?.completedMeals ?? 0,
            totalMeals: dashboard?.totalMeals ?? 0,
            onTap: () => _openStats(context),
          ),
          const SizedBox(height: 24),

          // Section: Today's plan items
          _buildSectionHeader(
            context,
            title: 'KẾ HOẠCH HÔM NAY',
            onSeeAll: null,
          ),
          const SizedBox(height: 12),

          // Meal items
          _buildMealSection(
            context,
            dashboard?.plannedItems ?? [],
            'Chưa có kế hoạch cho hôm nay',
          ),

          const SizedBox(height: 20),

          _buildCreatePlanCta(context),

          const SizedBox(height: 28),

          _AllPlansTab(provider: provider),

          const SizedBox(height: 24),

          // Quick actions
          _buildQuickActions(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
      ],
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    List<MealPlanItemDetail> items,
    String emptyMessage,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(context, emptyMessage);
    }

    // Group by meal type
    final grouped = <MealType, List<MealPlanItemDetail>>{};
    for (final item in items) {
      final mealType = MealType.fromString(item.mealType);
      grouped.putIfAbsent(mealType, () => []).add(item);
    }

    return Column(
      children: [
        for (final mealType in MealType.values)
          if (grouped.containsKey(mealType))
            PlannedMealCard(
              mealType: mealType,
              items: grouped[mealType]!,
              onAddItem: () => _addMeal(context, mealType),
              onTapItem: (item) => _openItemDetail(context, item),
              onLogAll: () => _logAllMeal(context, grouped[mealType]!),
              onMarkItemDone: (item) => _toggleItemCompletion(context, item),
              onConvertToLog: (item) => _convertItemToLog(context, item),
              onEditItem: (item) => _editItem(context, item),
              onDeleteItem: (item) => _deleteItem(context, item),
              onSkipItem: (item) => _skipItem(context, item),
            ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tạo kế hoạch dinh dưỡng bên dưới để bắt đầu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePlanCta(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tạo kế hoạch dinh dưỡng mới',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _createPlan(context),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo kế hoạch dinh dưỡng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lên thực đơn theo ngày hoặc trọn tuần mới',
                          style: TextStyle(
                            color: Color(0xFFD8F3DC),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 20,
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openCalendar(context),
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text('Lịch'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openStats(context),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Thống kê'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _addMeal(BuildContext context, MealType mealType) {
    // User cần có plan để thêm item
    // Nếu không có plan hôm nay, redirect sang tạo mới
    final plans = provider.plans;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bạn cần tạo kế hoạch trước'),
          action: SnackBarAction(
            label: 'Tạo',
            onPressed: () => _createPlan(context),
          ),
        ),
      );
      return;
    }

    // Lấy plan đầu tiên đang active
    final activePlan = plans.firstWhere(
      (p) => p.isActive,
      orElse: () => plans.first,
    );

    AddItemSheet.show(
      context: context,
      planId: activePlan.id,
      mealType: mealType,
      scheduledTime: _getDefaultMealTime(mealType),
    ).then((request) async {
      if (request != null && context.mounted) {
        final item = await provider.addItem(activePlan.id, request);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                item != null ? 'Đã thêm món' : 'Không thể thêm món',
              ),
            ),
          );
        }
      }
    });
  }

  DateTime _getDefaultMealTime(MealType mealType) {
    final now = DateTime.now();
    switch (mealType) {
      case MealType.breakfast:
        return DateTime(now.year, now.month, now.day, 7, 0);
      case MealType.lunch:
        return DateTime(now.year, now.month, now.day, 12, 0);
      case MealType.dinner:
        return DateTime(now.year, now.month, now.day, 18, 0);
      case MealType.snack:
        return DateTime(now.year, now.month, now.day, 10, 0);
    }
  }

  void _openItemDetail(BuildContext context, MealPlanItemDetail item) {
    if (item.foodId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(foodId: item.foodId!),
        ),
      );
    } else if (item.recipeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: item.recipeId!),
        ),
      );
    }
  }

  void _convertItemToLog(BuildContext context, MealPlanItemDetail item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi nhận ăn uống'),
        content: Text(
          'Chuyển "${item.displayName}" thành bản ghi ăn uống thực tế?',
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
      final request = ConvertToLogRequest(quantityG: null);

      // Find plan ID from item or provider
      final planId = item.mealPlanId ?? provider.plans.firstOrNull?.id;
      if (planId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy kế hoạch')),
          );
        }
        return;
      }

      final result = await provider.convertItemToLog(planId, item.id, request);

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

  void _editItem(BuildContext context, MealPlanItemDetail item) {
    final planId = item.mealPlanId ?? provider.plans.firstOrNull?.id;
    if (planId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không tìm thấy kế hoạch')));
      return;
    }

    EditItemSheet.show(
      context: context,
      planId: planId,
      item: item,
      onItemUpdated: () {
        provider.loadTodayDashboard();
      },
    );
  }

  void _toggleItemCompletion(
    BuildContext context,
    MealPlanItemDetail item,
  ) async {
    HapticFeedback.mediumImpact();
    final success = await provider.toggleItemCompletion(item.id, !item.isDone);
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
              provider.error != null && provider.error!.isNotEmpty
                  ? provider.error!
                  : 'Không thể cập nhật',
            ),
          ),
        );
      }
    }
  }

  void _deleteItem(BuildContext context, MealPlanItemDetail item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa món'),
        content: Text('Xóa "${item.displayName}" khỏi kế hoạch?'),
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
      final success = await provider.deleteItem(item.mealPlanId ?? '', item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Đã xóa' : 'Không thể xóa')),
        );
      }
    }
  }

  void _skipItem(BuildContext context, MealPlanItemDetail item) async {
    HapticFeedback.lightImpact();
    await provider.skipItem(item.mealPlanId ?? '', item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã bỏ qua "${item.displayName}"')),
      );
    }
  }

  void _logAllMeal(BuildContext context, List<MealPlanItemDetail> items) async {
    HapticFeedback.mediumImpact();
    final pendingCount = items.where((item) => !item.isDone).length;
    final completedCount = await provider.completeItems(items);
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

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Một số dữ liệu chưa tải được. Bạn có thể thử lại.',
              style: TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
          TextButton(
            onPressed: provider.loadAllForHome,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _createPlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMealPlanScreen()),
    ).then((_) {
      if (!context.mounted) return;
      provider.loadAllForHome();
    });
  }

  void _openCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealPlanCalendarScreen()),
    );
  }

  void _openStats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealPlanStatsScreen()),
    );
  }
}

/// Danh sách kế hoạch được gộp vào màn tổng quan.
class _AllPlansTab extends StatefulWidget {
  const _AllPlansTab({required this.provider});

  final MealPlanProvider provider;

  @override
  State<_AllPlansTab> createState() => _AllPlansTabState();
}

class _AllPlansTabState extends State<_AllPlansTab> {
  PlanFilter _currentFilter = PlanFilter.all;

  List<MealPlanListItem> get _filteredPlans {
    final plans = switch (_currentFilter) {
      PlanFilter.all => widget.provider.plans.toList(),
      PlanFilter.active =>
        widget.provider.plans.where((p) => p.isActive).toList(),
      PlanFilter.completed =>
        widget.provider.plans.where((p) => !p.isActive).toList(),
    };

    plans.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      final aDate = a.startDate ?? DateTime(2000);
      final bDate = b.startDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return plans;
  }

  @override
  Widget build(BuildContext context) {
    final plans = _filteredPlans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KẾ HOẠCH DINH DƯỠNG',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Theo dõi kế hoạch tuần và những kế hoạch trước đây',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        _buildFilterHeader(),
        const SizedBox(height: 14),
        if (plans.isEmpty)
          _buildEmptyState()
        else
          for (final plan in plans)
            _PlanCard(
              plan: plan,
              onTap: () => _openPlanDetail(context, plan),
              onDuplicate: () => _duplicatePlan(context, plan),
              onDelete: () => _deletePlan(context, plan),
            ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            PlanFilter.all,
            'Tất cả',
            widget.provider.plans.length,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            PlanFilter.active,
            'Đang hoạt động',
            widget.provider.plans.where((p) => p.isActive).length,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            PlanFilter.completed,
            'Đã kết thúc',
            widget.provider.plans.where((p) => !p.isActive).length,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(PlanFilter filter, String label, int count) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _currentFilter = filter),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.progressBackground.withValues(alpha: 0.45),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.progressBackground,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      label: Text(
        '$label${count > 0 ? '  $count' : ''}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_currentFilter) {
      case PlanFilter.all:
        message = 'Chưa có kế hoạch nào';
        icon = Icons.calendar_today_outlined;
        break;
      case PlanFilter.active:
        message = 'Không có kế hoạch đang hoạt động';
        icon = Icons.play_circle_outline;
        break;
      case PlanFilter.completed:
        message = 'Không có kế hoạch đã kết thúc';
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _openPlanDetail(BuildContext context, MealPlanListItem plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MealPlanDetailScreen(planId: plan.id)),
    ).then((_) => widget.provider.loadAllForHome());
  }

  void _duplicatePlan(BuildContext context, MealPlanListItem plan) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhân bản kế hoạch'),
        content: Text('Tạo bản sao của "${plan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nhân bản'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final request = DuplicatePlanRequest(
        newStartDate: DateTime.now(),
        newEndDate: plan.endDate,
      );

      final newPlan = await widget.provider.duplicatePlan(plan.id, request);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newPlan != null
                  ? 'Đã nhân bản thành công'
                  : 'Không thể nhân bản kế hoạch',
            ),
          ),
        );
      }
    }
  }

  void _deletePlan(BuildContext context, MealPlanListItem plan) async {
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
      final success = await widget.provider.deletePlan(plan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Đã kết thúc kế hoạch' : 'Không thể kết thúc kế hoạch',
            ),
          ),
        );
      }
    }
  }
}

/// Card hiển thị plan
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    this.onTap,
    this.onDuplicate,
    this.onDelete,
  });

  final MealPlanListItem plan;
  final VoidCallback? onTap;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = plan.totalItems > 0
        ? plan.completedItems / plan.totalItems
        : 0.0;
    final accent = plan.isActive ? AppColors.primary : AppColors.textSecondary;
    final durationDays = _durationDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: plan.isActive ? const Color(0xFFF7FBF8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: plan.isActive
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.progressBackground,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_planIcon, color: accent, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildBadge(
                                _planTypeLabel,
                                accent,
                                filled: false,
                              ),
                              _buildBadge(
                                plan.isActive ? 'Đang áp dụng' : 'Đã kết thúc',
                                plan.isActive
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                filled: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (plan.dateRangeText.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.date_range_outlined,
                                  size: 15,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    plan.dateRangeText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn kế hoạch',
                      onSelected: (value) {
                        switch (value) {
                          case 'duplicate':
                            onDuplicate?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined, size: 18),
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
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PlanMetric(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Mục tiêu mỗi ngày',
                        value: (plan.targetCalories ?? 0) > 0
                            ? '${plan.targetCalories} kcal'
                            : 'Chưa thiết lập',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PlanMetric(
                        icon: Icons.calendar_view_week_outlined,
                        label: 'Thời lượng',
                        value: durationDays > 0
                            ? '$durationDays ngày'
                            : 'Linh hoạt',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.totalItems > 0
                          ? '${plan.completedItems}/${plan.totalItems} món đã ăn'
                          : 'Chưa có món trong kế hoạch',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.progressBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (plan.currentStreak > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            size: 17,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${plan.currentStreak} ngày liên tiếp',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Xem chi tiết kế hoạch',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }

  String get _planTypeLabel {
    switch ((plan.planType ?? '').toLowerCase()) {
      case 'daily':
        return 'Kế hoạch ngày';
      case 'custom':
        return 'Kế hoạch tùy chỉnh';
      default:
        return 'Kế hoạch tuần';
    }
  }

  IconData get _planIcon {
    switch ((plan.planType ?? '').toLowerCase()) {
      case 'daily':
        return Icons.today_outlined;
      case 'custom':
        return Icons.tune_rounded;
      default:
        return Icons.calendar_view_week_rounded;
    }
  }

  int get _durationDays {
    final start = plan.startDate;
    final end = plan.endDate;
    if (start == null || end == null || end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
