import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_plan/models/meal_plan_models.dart';
import '../../tracking/models/nutrition_models.dart';
import '../models/vietnam_local_models.dart';
import '../providers/planned_vs_actual_provider.dart';

/// Daily planned-vs-actual report.
///
/// The old version aggregated seven days into one score/card and only showed a
/// calorie line per day. This screen intentionally keeps one selected calendar
/// day as the source of truth and exposes both complete meal lists.
class PlannedVsActualScreen extends StatefulWidget {
  const PlannedVsActualScreen({super.key});

  @override
  State<PlannedVsActualScreen> createState() => _PlannedVsActualScreenState();
}

class _PlannedVsActualScreenState extends State<PlannedVsActualScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlannedVsActualProvider>();
      provider.setDate(DateTime.now());
      provider.loadAll();
    });
  }

  Future<void> _selectDate(PlannedVsActualProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: _dateOnly(DateTime.now()),
      helpText: 'Chọn ngày xem báo cáo',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked == null || !mounted) return;
    provider.setDate(picked);
    await provider.loadAll();
  }

  Future<void> _changeDate(PlannedVsActualProvider provider, int offset) async {
    final next = provider.selectedDate.add(Duration(days: offset));
    if (next.isAfter(_dateOnly(DateTime.now()))) return;
    provider.setDate(next);
    await provider.loadAll();
  }

  void _openMeal({String? foodId, String? recipeId}) {
    final route = recipeId != null && recipeId.isNotEmpty
        ? MaterialPageRoute<void>(
            builder: (_) => RecipeDetailScreen(recipeId: recipeId),
          )
        : foodId != null && foodId.isNotEmpty
        ? MaterialPageRoute<void>(
            builder: (_) => FoodDetailScreen(foodId: foodId),
          )
        : null;
    if (route != null) Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Báo cáo dinh dưỡng theo ngày',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          Consumer<PlannedVsActualProvider>(
            builder: (_, provider, _) => IconButton(
              onPressed: () => _selectDate(provider),
              tooltip: 'Chọn ngày',
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PlannedVsActualProvider>(
          builder: (context, provider, _) {
            final hasContent =
                provider.summary != null ||
                provider.dailySummary != null ||
                provider.dailyPlan != null;
            if (provider.isLoading && !hasContent) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.loadAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  _DateNavigator(
                    date: provider.selectedDate,
                    loading: provider.isLoading,
                    onPrevious: () => _changeDate(provider, -1),
                    onNext: _isToday(provider.selectedDate)
                        ? null
                        : () => _changeDate(provider, 1),
                    onPick: () => _selectDate(provider),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _InlineError(
                      message: provider.errorMessage!,
                      onRetry: provider.loadAll,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _DailyProgressCard(
                    summary: provider.dailySummary,
                    plan: provider.dailyPlan,
                  ),
                  const SizedBox(height: 14),
                  _ComparisonCard(
                    analytics: provider.summary,
                    dailySummary: provider.dailySummary,
                    plan: provider.dailyPlan,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Danh sách món ăn',
                    subtitle: 'Chỉ hiển thị dữ liệu của ngày đang chọn',
                  ),
                  const SizedBox(height: 10),
                  _PlannedMealsCard(
                    items: provider.dailyPlan?.items ?? const [],
                    actualItems: provider.dailySummary?.mealLogs ?? const [],
                    onOpen: (item) =>
                        _openMeal(foodId: item.foodId, recipeId: item.recipeId),
                  ),
                  const SizedBox(height: 12),
                  _ActualMealsCard(
                    items: provider.dailySummary?.mealLogs ?? const [],
                    onOpen: (item) =>
                        _openMeal(foodId: item.foodId, recipeId: item.recipeId),
                  ),
                  if (provider.adherence != null) ...[
                    const SizedBox(height: 20),
                    _AdherenceCard(adherence: provider.adherence!),
                  ],
                  if (_hasDrift(provider.drift)) ...[
                    const SizedBox(height: 14),
                    _DailyDriftCard(drift: provider.drift!),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static bool _hasDrift(DriftAnalysis? drift) =>
      drift != null &&
      (drift.skippedMealsCount > 0 ||
          drift.unplannedIntakeCount > 0 ||
          drift.substitutedItemsCount > 0 ||
          drift.portionMismatchesCount > 0);

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isToday(DateTime date) =>
      _dateOnly(date) == _dateOnly(DateTime.now());
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.loading,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime date;
  final bool loading;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              _DateArrow(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Ngày trước',
                onTap: loading ? null : onPrevious,
              ),
              Expanded(
                child: InkWell(
                  onTap: loading ? null : onPick,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          _weekdayLabel(date.weekday),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _fullDate(date),
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_sameDate(date, DateTime.now())) ...[
                              const SizedBox(width: 8),
                              const _Badge(
                                label: 'Hôm nay',
                                color: Color(0xFF059669),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _DateArrow(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Ngày sau',
                onTap: loading ? null : onNext,
              ),
            ],
          ),
          if (loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Color(0xFFE8EFEA),
            ),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({required this.summary, required this.plan});

  final MealDaySummary? summary;
  final UserMealPlan? plan;

  @override
  Widget build(BuildContext context) {
    final actual = summary?.totalCalories ?? 0;
    final targetFromSummary = summary?.targetCalories ?? 0;
    final target = targetFromSummary > 0
        ? targetFromSummary
        : (plan?.targetCalories ?? 0).toDouble();
    final ratio = target > 0 ? actual / target : 0.0;
    final exceeded = target > 0 && actual > target;
    final accent = exceeded ? const Color(0xFFE5484D) : AppColors.primary;
    final difference = (actual - target).abs().round();

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.local_fire_department_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ trong ngày',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tự đặt lại khi chuyển sang ngày khác',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                actual.round().toString(),
                style: TextStyle(
                  color: accent,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 5, bottom: 3),
                child: Text(
                  'kcal đã ăn',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  target > 0
                      ? 'Mục tiêu ${target.round()} kcal'
                      : 'Chưa có mục tiêu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio.clamp(0.0, 1.0),
              color: accent,
              backgroundColor: const Color(0xFFE8EDEA),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  target <= 0
                      ? 'Thêm mục tiêu để theo dõi tiến độ'
                      : exceeded
                      ? 'Vượt $difference kcal'
                      : 'Còn $difference kcal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (target > 0)
                Text(
                  '${(ratio * 100).round()}%',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroProgress(
                  label: 'Protein',
                  value: summary?.totalProteinG ?? 0,
                  target: summary?.targetProteinG ?? 0,
                  color: const Color(0xFF3478F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroProgress(
                  label: 'Carbs',
                  value: summary?.totalCarbsG ?? 0,
                  target: summary?.targetCarbsG ?? 0,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroProgress(
                  label: 'Chất béo',
                  value: summary?.totalFatG ?? 0,
                  target: summary?.targetFatG ?? 0,
                  color: const Color(0xFFEF476F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = target > 0 ? value / target : 0.0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${value.round()}g',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            target > 0 ? '/ ${target.round()}g' : 'chưa đặt',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: ratio.clamp(0.0, 1.0),
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.analytics,
    required this.dailySummary,
    required this.plan,
  });

  final PlannedVsActualSummary? analytics;
  final MealDaySummary? dailySummary;
  final UserMealPlan? plan;

  @override
  Widget build(BuildContext context) {
    final planned = analytics?.totalPlanned;
    final summaryCalorieTarget = dailySummary?.targetCalories ?? 0;
    final planCalorieTarget = plan?.targetCalories ?? 0;
    final plannedKcal = summaryCalorieTarget > 0
        ? summaryCalorieTarget
        : planCalorieTarget > 0
        ? planCalorieTarget.toDouble()
        : planned?.caloriesKcal ?? 0;
    final plannedProtein = (dailySummary?.targetProteinG ?? 0) > 0
        ? dailySummary!.targetProteinG
        : planned?.proteinG ?? 0;
    final plannedCarbs = (dailySummary?.targetCarbsG ?? 0) > 0
        ? dailySummary!.targetCarbsG
        : planned?.carbsG ?? 0;
    final plannedFat = (dailySummary?.targetFatG ?? 0) > 0
        ? dailySummary!.targetFatG
        : planned?.fatG ?? 0;
    final actualKcal =
        dailySummary?.totalCalories ?? analytics?.totalActual.caloriesKcal ?? 0;
    final difference = actualKcal - plannedKcal;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kế hoạch và thực tế',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'So sánh riêng ngày đang chọn',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NutritionBlock(
                  label: 'Kế hoạch',
                  icon: Icons.event_note_rounded,
                  calories: plannedKcal,
                  protein: plannedProtein,
                  carbs: plannedCarbs,
                  fat: plannedFat,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NutritionBlock(
                  label: 'Thực tế',
                  icon: Icons.check_circle_outline_rounded,
                  calories: actualKcal,
                  protein:
                      dailySummary?.totalProteinG ??
                      analytics?.totalActual.proteinG ??
                      0,
                  carbs:
                      dailySummary?.totalCarbsG ??
                      analytics?.totalActual.carbsG ??
                      0,
                  fat:
                      dailySummary?.totalFatG ??
                      analytics?.totalActual.fatG ??
                      0,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _differenceColor(difference).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  difference.abs() < 1
                      ? Icons.check_circle_rounded
                      : difference > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: _differenceColor(difference),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plannedKcal <= 0
                        ? 'Ngày này chưa có thực đơn kế hoạch.'
                        : difference.abs() < 1
                        ? 'Lượng calo khớp với kế hoạch.'
                        : difference > 0
                        ? 'Thực tế cao hơn kế hoạch ${difference.abs().round()} kcal.'
                        : 'Thực tế thấp hơn kế hoạch ${difference.abs().round()} kcal.',
                    style: TextStyle(
                      color: _differenceColor(difference),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _differenceColor(double value) {
    if (value.abs() < 1) return const Color(0xFF059669);
    return value > 0 ? const Color(0xFFE5484D) : const Color(0xFF0284C7);
  }
}

class _NutritionBlock extends StatelessWidget {
  const _NutritionBlock({
    required this.label,
    required this.icon,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.color,
  });

  final String label;
  final IconData icon;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '${calories.round()} kcal',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'P ${protein.round()} · C ${carbs.round()} · F ${fat.round()}g',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedMealsCard extends StatelessWidget {
  const _PlannedMealsCard({
    required this.items,
    required this.actualItems,
    required this.onOpen,
  });

  final List<MealPlanItemModel> items;
  final List<MealLogItem> actualItems;
  final ValueChanged<MealPlanItemModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final sorted = [
      ...items,
    ]..sort((a, b) => _mealOrder(a.mealType).compareTo(_mealOrder(b.mealType)));
    return _MealListShell(
      icon: Icons.event_note_rounded,
      title: 'Món trong kế hoạch',
      count: items.length,
      color: AppColors.primary,
      emptyText: 'Ngày này chưa có món trong kế hoạch.',
      children: [
        for (var index = 0; index < sorted.length; index++) ...[
          _PlannedMealTile(
            item: sorted[index],
            completed:
                sorted[index].isCompleted ||
                actualItems.any(
                  (log) => log.mealPlanItemId == sorted[index].id,
                ),
            onTap: () => onOpen(sorted[index]),
          ),
          if (index < sorted.length - 1) const Divider(height: 1, indent: 52),
        ],
      ],
    );
  }
}

class _ActualMealsCard extends StatelessWidget {
  const _ActualMealsCard({required this.items, required this.onOpen});

  final List<MealLogItem> items;
  final ValueChanged<MealLogItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]
      ..sort((a, b) {
        final aTime = a.loggedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.loggedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });
    return _MealListShell(
      icon: Icons.task_alt_rounded,
      title: 'Món đã ăn thực tế',
      count: items.length,
      color: const Color(0xFF2563EB),
      emptyText: 'Chưa ghi nhận món đã ăn trong ngày này.',
      children: [
        for (var index = 0; index < sorted.length; index++) ...[
          _ActualMealTile(
            item: sorted[index],
            onTap: () => onOpen(sorted[index]),
          ),
          if (index < sorted.length - 1) const Divider(height: 1, indent: 52),
        ],
      ],
    );
  }
}

class _MealListShell extends StatelessWidget {
  const _MealListShell({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.emptyText,
    required this.children,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _Badge(label: '$count món', color: color),
              ],
            ),
          ),
          const Divider(height: 1),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.no_meals_outlined, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _PlannedMealTile extends StatelessWidget {
  const _PlannedMealTile({
    required this.item,
    required this.completed,
    required this.onTap,
  });

  final MealPlanItemModel item;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.foodId != null || item.recipeId != null ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MealIcon(mealType: item.mealType, completed: completed),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayName,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Badge(
                        label: mealTypeLabelVi(item.mealType),
                        color: _mealTypeColor(item.mealType),
                      ),
                      Text(
                        formatNutritionFacts(
                          quantityG: item.quantityG,
                          caloriesKcal: item.targetCalories,
                          proteinG: item.proteinG,
                          carbsG: item.carbsG,
                          fatG: item.fatG,
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                      Text(
                        completed ? 'Đã ăn' : 'Chưa ăn',
                        style: TextStyle(
                          color: completed
                              ? const Color(0xFF059669)
                              : const Color(0xFF9A6700),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
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

class _ActualMealTile extends StatelessWidget {
  const _ActualMealTile({required this.item, required this.onTap});

  final MealLogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.foodId != null || item.recipeId != null ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MealIcon(mealType: item.mealType, completed: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayName,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    children: [
                      _Badge(
                        label: mealTypeLabelVi(item.mealType),
                        color: _mealTypeColor(item.mealType),
                      ),
                      Text(
                        formatNutritionFacts(
                          quantityG: item.quantityG,
                          caloriesKcal: item.caloriesKcal,
                          proteinG: item.proteinG,
                          carbsG: item.carbsG,
                          fatG: item.fatG,
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                      if (item.loggedAt != null)
                        Text(
                          _timeLabel(item.loggedAt!),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
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

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.adherence});

  final AdherenceScore adherence;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(adherence.rating);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  adherence.overallScore.round().toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mức độ bám sát trong ngày',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _ratingLabel(adherence.rating),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _ScoreRow(
            label: 'Hoàn thành món',
            value: adherence.mealCompletionRate,
          ),
          const SizedBox(height: 10),
          _ScoreRow(
            label: 'Khớp lượng calo',
            value: adherence.calorieDeviationScore,
          ),
          const SizedBox(height: 10),
          _ScoreRow(label: 'Khớp macro', value: adherence.macroDeviationScore),
          const SizedBox(height: 10),
          _ScoreRow(
            label: 'Hạn chế ngoài kế hoạch',
            value: adherence.unplannedPenaltyScore,
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 138,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (value / 100).clamp(0.0, 1.0),
              color: AppColors.primary,
              backgroundColor: const Color(0xFFE8EDEA),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 25,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyDriftCard extends StatelessWidget {
  const _DailyDriftCard({required this.drift});

  final DriftAnalysis drift;

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if (drift.skippedMealsCount > 0)
        '${drift.skippedMealsCount} món trong kế hoạch chưa hoàn thành',
      if (drift.unplannedIntakeCount > 0)
        '${drift.unplannedIntakeCount} món ngoài kế hoạch',
      if (drift.substitutedItemsCount > 0)
        '${drift.substitutedItemsCount} món đã thay thế',
      if (drift.portionMismatchesCount > 0)
        '${drift.portionMismatchesCount} món lệch khẩu phần',
    ];
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: Color(0xFFD97706), size: 21),
              SizedBox(width: 8),
              Text(
                'Điểm cần chú ý',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MealIcon extends StatelessWidget {
  const _MealIcon({required this.mealType, required this.completed});

  final String mealType;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? const Color(0xFF059669)
        : _mealTypeColor(mealType);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        shape: BoxShape.circle,
      ),
      child: Icon(
        completed ? Icons.check_rounded : Icons.restaurant_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}

class _DateArrow extends StatelessWidget {
  const _DateArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(
        icon,
        color: onTap == null ? Colors.grey.shade300 : AppColors.primary,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFC2410C)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF9A3412), fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

int _mealOrder(String type) => switch (type.toLowerCase()) {
  'breakfast' => 0,
  'lunch' => 1,
  'dinner' => 2,
  _ => 3,
};

Color _mealTypeColor(String type) => switch (type.toLowerCase()) {
  'breakfast' => const Color(0xFFF97316),
  'lunch' => const Color(0xFF059669),
  'dinner' => const Color(0xFF2563EB),
  _ => const Color(0xFF7C3AED),
};

Color _ratingColor(String rating) => switch (rating.toUpperCase()) {
  'EXCELLENT' => const Color(0xFF059669),
  'GOOD' => const Color(0xFF0284C7),
  'FAIR' => const Color(0xFFD97706),
  _ => const Color(0xFFE5484D),
};

String _ratingLabel(String rating) => switch (rating.toUpperCase()) {
  'EXCELLENT' => 'Rất tốt',
  'GOOD' => 'Tốt',
  'FAIR' => 'Cần cải thiện',
  'POOR' => 'Chưa đạt',
  _ => 'Đang cập nhật',
};

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'Thứ Hai',
  DateTime.tuesday => 'Thứ Ba',
  DateTime.wednesday => 'Thứ Tư',
  DateTime.thursday => 'Thứ Năm',
  DateTime.friday => 'Thứ Sáu',
  DateTime.saturday => 'Thứ Bảy',
  _ => 'Chủ Nhật',
};

String _fullDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
