import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/calorie_progress_ring.dart';
import '../widgets/meal_item_tile.dart';
import 'meal_plan_detail_screen.dart';
import 'create_meal_plan_screen.dart';
import 'meal_plan_stats_screen.dart';
import 'meal_plan_calendar_screen.dart';

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
      context.read<MealPlanProvider>().loadPlans();
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
    final adherence = provider.todayAdherence;
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
    // TODO: Open add item sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thêm bữa ${mealType.labelVi}')),
    );
  }

  void _openItemDetail(BuildContext context, MealPlanItemDetail item) {
    // TODO: Navigate to food/recipe detail
  }

  void _logAllMeal(BuildContext context, List<MealPlanItemDetail> items) {
    HapticFeedback.mediumImpact();
    // TODO: Mark all as done
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã log ${items.length} món')),
    );
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
class _AllPlansTab extends StatelessWidget {
  const _AllPlansTab({required this.provider});

  final MealPlanProvider provider;

  @override
  Widget build(BuildContext context) {
    final plans = provider.plans;

    if (plans.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPlans(),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có kế hoạch nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo kế hoạch để bắt đầu theo dõi dinh dưỡng',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
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

  void _duplicatePlan(BuildContext context, MealPlanListItem plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nhân bản "${plan.title}"')),
    );
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
      final success = await provider.deletePlan(plan.id);
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
    ).then((_) => provider.loadPlans());
  }
}

/// Tab lịch sử
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.provider});

  final MealPlanProvider provider;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement history tab
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Lịch sử kế hoạch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các kế hoạch đã kết thúc sẽ hiển thị ở đây',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
