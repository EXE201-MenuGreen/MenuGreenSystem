import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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

class _MealPlanScreenState extends State<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlanProvider>().loadAllForHome();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Tất cả'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.plans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _TodayTab(provider: provider),
              _AllPlansTab(provider: provider),
              _HistoryTab(provider: provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlan(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo kế hoạch'),
        backgroundColor: AppColors.primary,
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

  void _createPlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMealPlanScreen()),
    ).then((_) {
      if (!context.mounted) return;
      context.read<MealPlanProvider>().loadAllForHome();
    });
  }
}

/// Tab hôm nay - Dashboard
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
        padding: const EdgeInsets.all(16),
        children: [
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
            onTap: () => _showTodayDetails(context, dashboard),
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

          const SizedBox(height: 24),

          // Quick actions
          _buildQuickActions(context),
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
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Xem tất cả'),
          ),
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
              onMarkItemDone: (item) => _markItemDone(context, item),
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
          Icon(
            Icons.restaurant_menu,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _createPlan(context),
            icon: const Icon(Icons.add),
            label: const Text('Tạo kế hoạch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
              content: Text(item != null ? 'Đã thêm món' : 'Không thể thêm món'),
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
      // Navigate to food detail
      // TODO: Implement food detail navigation
    } else if (item.recipeId != null) {
      // Navigate to recipe detail
      // TODO: Implement recipe detail navigation
    }
  }

  void _convertItemToLog(BuildContext context, MealPlanItemDetail item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi nhận ăn uống'),
        content: Text('Chuyển "${item.displayName}" thành bản ghi ăn uống thực tế?'),
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
      final request = ConvertToLogRequest(
        loggedAt: DateTime.now(),
        quantityG: null,
      );

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
            SnackBar(content: Text(result?.message ?? provider.error ?? 'Không thể ghi nhận')),
          );
        }
      }
    }
  }

  void _editItem(BuildContext context, MealPlanItemDetail item) {
    final planId = item.mealPlanId ?? provider.plans.firstOrNull?.id;
    if (planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy kế hoạch')),
      );
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

  void _markItemDone(BuildContext context, MealPlanItemDetail item) async {
    HapticFeedback.mediumImpact();
    await provider.markItemDone(item.mealPlanId ?? '', item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hoàn thành "${item.displayName}"')),
      );
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
    for (final item in items.where((i) => !i.isDone)) {
      await provider.markItemDone(item.mealPlanId ?? '', item.id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã log ${items.length} món')),
      );
    }
  }

  void _showTodayDetails(BuildContext context, MealPlanDayDashboard? dashboard) {
    // TODO: Show detailed nutrition info
  }

  void _createPlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMealPlanScreen()),
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

/// Tab tất cả - List plans
class _AllPlansTab extends StatefulWidget {
  const _AllPlansTab({required this.provider});

  final MealPlanProvider provider;

  @override
  State<_AllPlansTab> createState() => _AllPlansTabState();
}

class _AllPlansTabState extends State<_AllPlansTab> {
  PlanFilter _currentFilter = PlanFilter.all;

  List<MealPlanListItem> get _filteredPlans {
    final plans = widget.provider.plans;
    switch (_currentFilter) {
      case PlanFilter.all:
        return plans;
      case PlanFilter.active:
        return plans.where((p) => p.isActive).toList();
      case PlanFilter.completed:
        return plans.where((p) => !p.isActive).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _filteredPlans;

    if (plans.isEmpty) {
      return Column(
        children: [
          _buildFilterHeader(),
          Expanded(child: _buildEmptyState(context)),
        ],
      );
    }

    return Column(
      children: [
        _buildFilterHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => widget.provider.loadPlans(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _PlanCard(
                  plan: plan,
                  onTap: () => _openPlanDetail(context, plan),
                  onDuplicate: () => _duplicatePlan(context, plan),
                  onDelete: () => _deletePlan(context, plan),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterChip(PlanFilter.all, 'Tất cả', widget.provider.plans.length),
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
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.progressBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.progressBackground,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;

    switch (_currentFilter) {
      case PlanFilter.all:
        message = 'Chưa có kế hoạch nào\nTạo kế hoạch đầu tiên!';
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (_currentFilter == PlanFilter.all) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createPlan(context),
              icon: const Icon(Icons.add),
              label: const Text('Tạo kế hoạch đầu tiên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openPlanDetail(BuildContext context, MealPlanListItem plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealPlanDetailScreen(planId: plan.id),
      ),
    );
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
      final success = await widget.provider.deletePlan(plan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xóa kế hoạch' : 'Không thể xóa kế hoạch'),
          ),
        );
      }
    }
  }

  void _createPlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMealPlanScreen()),
    ).then((_) => widget.provider.loadPlans());
  }
}

/// Tab lịch sử
class _HistoryTab extends StatefulWidget {
  const _HistoryTab({required this.provider});

  final MealPlanProvider provider;

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  PlanFilter _currentFilter = PlanFilter.all;

  List<MealPlanListItem> get _filteredPlans {
    final plans = widget.provider.plans;
    switch (_currentFilter) {
      case PlanFilter.all:
        return plans;
      case PlanFilter.active:
        return plans.where((p) => p.isActive).toList();
      case PlanFilter.completed:
        return plans.where((p) => !p.isActive).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _filteredPlans;
    final completedPlans = widget.provider.plans.where((p) => !p.isActive).toList();

    if (widget.provider.isLoading && widget.provider.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildFilterChip(PlanFilter.all, 'Tất cả', widget.provider.plans.length),
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
                completedPlans.length,
              ),
            ],
          ),
        ),

        // Plans list
        Expanded(
          child: plans.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => widget.provider.loadPlans(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlanCard(
                          plan: plan,
                          onTap: () => _viewPlan(context, plan),
                          onDuplicate: () => _duplicatePlan(context, plan),
                          onDelete: () => _deletePlan(context, plan),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(PlanFilter filter, String label, int count) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.progressBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.progressBackground,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_currentFilter) {
      case PlanFilter.all:
        message = 'Chưa có kế hoạch nào\nTạo kế hoạch đầu tiên của bạn!';
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
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

  void _viewPlan(BuildContext context, MealPlanListItem plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealPlanDetailScreen(planId: plan.id),
      ),
    ).then((_) {
      widget.provider.loadPlans();
    });
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

    if (confirmed == true) {
      final success = await widget.provider.deletePlan(plan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Đã xóa kế hoạch' : 'Không thể xóa')),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.progressBackground),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.dateRangeText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
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
              ),
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${plan.completedItems}/${plan.totalItems} bữa',
                              style: const TextStyle(
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
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Streak badge
              if (plan.currentStreak > 0) ...[
                const SizedBox(height: 12),
                StreakWidget(
                  currentStreak: plan.currentStreak,
                  size: 'small',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
