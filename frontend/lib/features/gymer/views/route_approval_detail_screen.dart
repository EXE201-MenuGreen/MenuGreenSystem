import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/meal_schedule_format.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_plan/models/meal_plan_models.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../models/route_approval_detail.dart';
import '../utils/route_approval_period.dart';

@visibleForTesting
bool isRouteMealCompleted(
  MealPlanItemModel item,
  Iterable<MealLogItem> actualMeals,
) =>
    item.isCompleted || actualMeals.any((log) => log.mealPlanItemId == item.id);

@visibleForTesting
MealPlanItemModel? resolveCurrentRouteMealItem(
  RouteApprovalMeal snapshot,
  UserMealPlan currentPlan,
) {
  for (final item in currentPlan.items) {
    if (item.id == snapshot.id) return item;
  }

  final mealType = snapshot.mealType.trim().toLowerCase();
  final candidates = currentPlan.items.where((item) {
    if (item.mealType.trim().toLowerCase() != mealType) return false;
    if (snapshot.plannedDate != null &&
        item.plannedDate != null &&
        !DateUtils.isSameDay(snapshot.plannedDate, item.plannedDate)) {
      return false;
    }
    if (snapshot.foodId?.isNotEmpty == true) {
      return item.foodId == snapshot.foodId;
    }
    if (snapshot.recipeId?.isNotEmpty == true) {
      return item.recipeId == snapshot.recipeId;
    }
    return item.displayName.trim().toLowerCase() ==
        snapshot.name.trim().toLowerCase();
  }).toList();

  if (candidates.length == 1) return candidates.single;
  if (snapshot.scheduledTime?.isNotEmpty == true) {
    final rawScheduled = snapshot.scheduledTime!;
    final scheduled = rawScheduled.length > 5
        ? rawScheduled.substring(0, 5)
        : rawScheduled;
    for (final item in candidates) {
      final currentTime = item.scheduledTime ?? '';
      if (currentTime.startsWith(scheduled)) return item;
    }
  }
  return candidates.isEmpty ? null : candidates.first;
}

String _configurationScope(RouteApprovalDetail detail) =>
    RouteApprovalPeriod.normalizeScope(
      requestType: detail.requestType,
      configurationScope: detail.configurationScope,
    );

DateTime _configurationStart(RouteApprovalDetail detail) {
  if (detail.configurationStartDate != null) {
    return detail.configurationStartDate!;
  }
  if (_configurationScope(detail) == 'day' && detail.days.isNotEmpty) {
    return detail.days.first.date;
  }
  final fallback = detail.weekStartDate;
  return _configurationScope(detail) == 'month'
      ? DateTime(fallback.year, fallback.month)
      : fallback;
}

DateTime _configurationEnd(RouteApprovalDetail detail) {
  if (detail.configurationEndDate != null) {
    return detail.configurationEndDate!;
  }
  final start = _configurationStart(detail);
  return switch (_configurationScope(detail)) {
    'week' => start.add(const Duration(days: 6)),
    'month' => DateTime(start.year, start.month + 1, 0),
    _ => start,
  };
}

class RouteApprovalDetailScreen extends StatefulWidget {
  const RouteApprovalDetailScreen({
    super.key,
    required this.requestId,
    this.initialSummary,
  });

  final String requestId;
  final Map<String, dynamic>? initialSummary;

  @override
  State<RouteApprovalDetailScreen> createState() =>
      _RouteApprovalDetailScreenState();
}

class _RouteApprovalDetailScreenState extends State<RouteApprovalDetailScreen> {
  RouteApprovalDetail? _detail;
  String? _error;
  bool _loading = true;
  final Set<String> _updatingMealIds = <String>{};
  final MealPlanRepository _mealPlanRepository = MealPlanRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await AdvancedRepository().ptResult(widget.requestId);
      final merged = <String, dynamic>{...?widget.initialSummary, ...raw};
      final summaryRequestType = widget.initialSummary?['requestType']
          ?.toString()
          .trim();
      if (summaryRequestType?.isNotEmpty == true) {
        // Legacy detail responses omitted RequestType and fell back to
        // WeeklyReport. The list response still contains the correct type.
        merged['requestType'] = summaryRequestType;
      }
      var detail = RouteApprovalDetail.fromJson(merged);
      detail = await _loadCurrentMealPlans(detail);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(error);
        _loading = false;
      });
    }
  }

  Future<RouteApprovalDetail> _loadCurrentMealPlans(
    RouteApprovalDetail detail,
  ) async {
    final dates = _datesToDisplay(detail);
    if (dates.isEmpty) return detail;

    // Route-approval reports contain a frozen meal snapshot. Always resolve the
    // exact referenced plan first so a PT edit/approval cannot keep displaying
    // the old total (for example 1845 instead of the current 2000 kcal).
    final exactPlanFuture = detail.mealPlanId?.trim().isNotEmpty == true
        ? _mealPlanRepository.getPlanDetail(detail.mealPlanId!)
        : Future.value(null);
    final plansFuture = Future.wait(
      dates.map(_mealPlanRepository.getByDateFresh),
    );
    final actualMealsFuture = Future.wait(
      dates.map(NutritionTrackingRepository().getDailySummary),
    );
    final exactPlan = await exactPlanFuture;
    final plans = await plansFuture;
    final actualMealsByDay = await actualMealsFuture;
    final snapshotDays = {
      for (final day in detail.days) _dateKey(day.date): day,
    };
    final resolvedDays = <RouteApprovalDay>[];

    for (var index = 0; index < plans.length; index++) {
      final date = dates[index];
      final plan = plans[index];
      final actualMeals = actualMealsByDay[index]?.mealLogs ?? const [];
      final exactItems =
          exactPlan?.items.where((item) {
            if (item.plannedDate == null) return dates.length == 1;
            return _dateKey(item.plannedDate!) == _dateKey(date);
          }).toList() ??
          const [];
      if (exactItems.isNotEmpty) {
        resolvedDays.add(
          RouteApprovalDay(
            date: date,
            meals: exactItems
                .map(
                  (item) => RouteApprovalMeal(
                    id: item.id,
                    mealType: item.mealType ?? 'snack',
                    name:
                        (item.foodName ??
                                item.recipeName ??
                                item.customName ??
                                '')
                            .trim()
                            .isNotEmpty
                        ? (item.foodName ?? item.recipeName ?? item.customName)!
                        : 'Món trong kế hoạch',
                    calories: item.targetCalories ?? 0,
                    isCompleted:
                        item.isCompleted ||
                        actualMeals.any((log) => log.mealPlanItemId == item.id),
                    foodId: item.foodId,
                    recipeId: item.recipeId,
                    plannedDate: item.plannedDate ?? date,
                    scheduledTime: item.scheduledTime == null
                        ? null
                        : '${item.scheduledTime!.hour.toString().padLeft(2, '0')}:'
                              '${item.scheduledTime!.minute.toString().padLeft(2, '0')}',
                    quantityG: item.quantityG,
                    proteinG: item.proteinG,
                    carbsG: item.carbsG,
                    fatG: item.fatG,
                    ingredients: item.ingredients,
                  ),
                )
                .toList(),
          ),
        );
      } else if (plan != null && plan.items.isNotEmpty) {
        resolvedDays.add(
          RouteApprovalDay(
            date: date,
            meals: plan.items
                .map(
                  (item) => RouteApprovalMeal(
                    id: item.id,
                    mealType: item.mealType,
                    name: item.displayName,
                    calories: item.targetCalories,
                    isCompleted: isRouteMealCompleted(item, actualMeals),
                    foodId: item.foodId,
                    recipeId: item.recipeId,
                    plannedDate: item.plannedDate ?? date,
                    scheduledTime: item.scheduledTime,
                    quantityG: item.quantityG,
                    proteinG: item.proteinG,
                    carbsG: item.carbsG,
                    fatG: item.fatG,
                  ),
                )
                .toList(),
          ),
        );
      } else {
        resolvedDays.add(
          snapshotDays[_dateKey(date)] ??
              RouteApprovalDay(date: date, meals: const []),
        );
      }
    }
    return detail.copyWith(days: resolvedDays);
  }

  List<DateTime> _datesToDisplay(RouteApprovalDetail detail) {
    if (_isRouteApproval(detail)) {
      final createdDate = detail.createdAt?.toLocal();
      if (createdDate != null) {
        final matchingSnapshot = detail.days.where(
          (day) => _dateKey(day.date) == _dateKey(createdDate),
        );
        if (matchingSnapshot.isNotEmpty) {
          return <DateTime>[matchingSnapshot.first.date];
        }
      }

      final populated = detail.days
          .where((day) => day.meals.isNotEmpty)
          .toList();
      if (populated.length == 1) return <DateTime>[populated.single.date];
      return <DateTime>[createdDate ?? detail.weekStartDate];
    }

    final snapshotDates = detail.days.map((day) => day.date).toList();
    if (snapshotDates.isNotEmpty) return snapshotDates;
    return List.generate(
      7,
      (index) => detail.weekStartDate.add(Duration(days: index)),
    );
  }

  bool _isRouteApproval(RouteApprovalDetail detail) =>
      detail.requestType.trim().toLowerCase() == 'routeapproval';

  Future<void> _toggleMeal(RouteApprovalMeal meal, bool value) async {
    if (meal.id.isEmpty || _updatingMealIds.contains(meal.id)) return;
    setState(() => _updatingMealIds.add(meal.id));
    try {
      var currentItemId = meal.id;
      if (meal.plannedDate != null) {
        final currentPlan = await _mealPlanRepository.getByDateFresh(
          meal.plannedDate!,
        );
        if (currentPlan != null) {
          final currentItem = resolveCurrentRouteMealItem(meal, currentPlan);
          if (currentItem == null) {
            throw Exception('Meal plan item not found.');
          }
          currentItemId = currentItem.id;
        }
      }
      await _mealPlanRepository.toggleItem(currentItemId, value);
      if (!mounted || _detail == null) return;
      setState(() {
        _detail = _detail!.copyWith(
          days: _detail!.days
              .map(
                (day) => RouteApprovalDay(
                  date: day.date,
                  meals: day.meals
                      .map(
                        (item) => item.id == meal.id
                            ? item.copyWith(
                                id: currentItemId,
                                isCompleted: value,
                              )
                            : item,
                      )
                      .toList(),
                ),
              )
              .toList(),
        );
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _updatingMealIds.remove(meal.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          _detail == null
              ? 'Chi tiết lộ trình'
              : 'Lộ trình ${RouteApprovalPeriod.scopeLabel(_configurationScope(_detail!))} '
                    '${RouteApprovalPeriod.titleDateLabel(_configurationScope(_detail!), _configurationStart(_detail!))}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _buildDetail(_detail!),
    );
  }

  Widget _buildDetail(RouteApprovalDetail detail) {
    final populatedDays = detail.days
        .where((day) => day.meals.isNotEmpty)
        .toList();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _SummaryCard(detail: detail),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Ghi chú từ PT',
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.primary,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: detail.ptComment.trim().isEmpty
                    ? const Color(0xFFF9FAFB)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: detail.ptComment.trim().isEmpty
                      ? const Color(0xFFF3F4F6)
                      : AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    detail.ptComment.trim().isEmpty
                        ? Icons.edit_note_rounded
                        : Icons.format_quote_rounded,
                    size: 20,
                    color: detail.ptComment.trim().isEmpty
                        ? Colors.grey.shade400
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      detail.ptComment.trim().isEmpty
                          ? 'PT chưa để lại ghi chú.'
                          : detail.ptComment.trim(),
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: detail.ptComment.trim().isEmpty
                            ? Colors.grey.shade500
                            : const Color(0xFF1F2937),
                        fontStyle: detail.ptComment.trim().isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontWeight: detail.ptComment.trim().isEmpty
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Bữa ăn và món ăn',
            icon: Icons.restaurant_menu_rounded,
            iconColor: AppColors.primary,
            child: populatedDays.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Lộ trình này chưa có món ăn.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < populatedDays.length;
                        index++
                      ) ...[
                        _DayMealsCard(
                          day: populatedDays[index],
                          updatingMealIds: _updatingMealIds,
                          status: detail.status,
                          onToggleMeal: _toggleMeal,
                        ),
                        if (index < populatedDays.length - 1)
                          const Divider(height: 16),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final isPending = detail.status.trim().toLowerCase() == 'pending';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFFFBEB)
                      : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: isPending
                      ? Border.all(color: const Color(0xFFFDE68A))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isPending
                          ? Icons.lock_outline_rounded
                          : Icons.check_box_outlined,
                      size: 18,
                      color: isPending
                          ? const Color(0xFFD97706)
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPending
                            ? 'Lộ trình đang chờ PT duyệt. Tính năng đánh dấu món ăn sẽ mở sau khi PT phản hồi.'
                            : 'Đánh dấu món đã ăn để PT theo dõi tiến độ của bạn.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isPending
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isPending
                              ? const Color(0xFFB45309)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});

  final RouteApprovalDetail detail;

  @override
  Widget build(BuildContext context) {
    final scope = _configurationScope(detail);
    final period = RouteApprovalPeriod.periodLabel(
      scope: scope,
      start: _configurationStart(detail),
      end: _configurationEnd(detail),
    );
    final description = detail.studentNote.trim().isEmpty
        ? 'Lộ trình dinh dưỡng gửi PT duyệt.'
        : detail.studentNote.trim();

    final plannedCalories = detail.plannedCaloriesPerDay;
    final displayedCalories = plannedCalories ?? detail.configuredCalorieTarget;
    final hasCalories = displayedCalories != null;
    final showConfiguredTarget =
        plannedCalories != null &&
        detail.configuredCalorieTarget != null &&
        plannedCalories != detail.configuredCalorieTarget;
    final hasMacros =
        detail.targetProteinG != null ||
        detail.targetCarbsG != null ||
        detail.targetFatG != null;

    return Column(
      children: [
        _DetailSection(
          title: 'Tổng quan',
          icon: Icons.space_dashboard_rounded,
          iconColor: AppColors.primary,
          child: Column(
            children: [
              _InfoRow('Mô tả', description),
              _InfoRow('Loại cấu hình', RouteApprovalPeriod.scopeLabel(scope)),
              _InfoRow('Thời gian', period),
              _InfoRow('Thời lượng', RouteApprovalPeriod.durationLabel(scope)),
              _StatusInfoRow('Trạng thái', detail.status),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Mục tiêu dinh dưỡng',
          icon: Icons.insights_rounded,
          iconColor: AppColors.primary,
          child: (!hasCalories && !hasMacros)
              ? const Text(
                  'Chưa có mục tiêu dinh dưỡng cho lộ trình này.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasCalories) ...[
                      // Hero Calorie Card (System Green Gradient Theme)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.08),
                              AppColors.primary.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  plannedCalories == null
                                      ? 'Mục tiêu Năng lượng'
                                      : 'Năng lượng lộ trình',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$displayedCalories kcal/ngày',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (showConfiguredTarget) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Mục tiêu cấu hình: '
                                '${detail.configuredCalorieTarget} kcal/ngày',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (detail.configuredMinCalories != null ||
                                detail.configuredMaxCalories != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (detail.configuredMinCalories != null)
                                    Expanded(
                                      child: _CalorieLimitBadge(
                                        icon: Icons.arrow_downward_rounded,
                                        label: 'Món tối thiểu',
                                        value:
                                            '${detail.configuredMinCalories} kcal',
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  if (detail.configuredMinCalories != null &&
                                      detail.configuredMaxCalories != null)
                                    const SizedBox(width: 8),
                                  if (detail.configuredMaxCalories != null)
                                    Expanded(
                                      child: _CalorieLimitBadge(
                                        icon: Icons.arrow_upward_rounded,
                                        label: 'Món tối đa',
                                        value:
                                            '${detail.configuredMaxCalories} kcal',
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (hasMacros) ...[
                      const Text(
                        'Phân bổ Macros',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (detail.targetProteinG != null)
                            Expanded(
                              child: _MacroCard(
                                icon: Icons.fitness_center_rounded,
                                label: 'Protein',
                                value: '${detail.targetProteinG} g',
                                bgColor: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                color: AppColors.primary,
                              ),
                            ),
                          if (detail.targetProteinG != null)
                            const SizedBox(width: 8),
                          if (detail.targetCarbsG != null)
                            Expanded(
                              child: _MacroCard(
                                icon: Icons.bakery_dining_rounded,
                                label: 'Carbs',
                                value: '${detail.targetCarbsG} g',
                                bgColor: AppColors.primary.withValues(
                                  alpha: 0.05,
                                ),
                                borderColor: AppColors.primary.withValues(
                                  alpha: 0.18,
                                ),
                                color: AppColors.primary,
                              ),
                            ),
                          if (detail.targetCarbsG != null)
                            const SizedBox(width: 8),
                          if (detail.targetFatG != null)
                            Expanded(
                              child: _MacroCard(
                                icon: Icons.water_drop_outlined,
                                label: 'Fat',
                                value: '${detail.targetFatG} g',
                                bgColor: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final primaryColor = iconColor ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: primaryColor),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  const _StatusInfoRow(this.label, this.status);
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();
    final (statusLabel, bgColor, textColor, borderColor) = switch (s) {
      'pending' => (
        'Chờ PT phản hồi',
        const Color(0xFFFFFBEB),
        const Color(0xFFD97706),
        const Color(0xFFFDE68A),
      ),
      'reviewed' => (
        'Đã duyệt',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'accepted' => (
        'Đã chấp nhận',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'applied' => (
        'Đã áp dụng',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'rejected' => (
        'Đã từ chối',
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        const Color(0xFFFECACA),
      ),
      _ => (
        status,
        const Color(0xFFF3F4F6),
        AppColors.textSecondary,
        const Color(0xFFE5E7EB),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 110,
            child: Text(
              'Trạng thái',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4.5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textColor,
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

class _CalorieLimitBadge extends StatelessWidget {
  const _CalorieLimitBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: color,
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

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color bgColor;
  final Color borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayMealsCard extends StatelessWidget {
  const _DayMealsCard({
    required this.day,
    required this.updatingMealIds,
    required this.status,
    required this.onToggleMeal,
  });

  final RouteApprovalDay day;
  final Set<String> updatingMealIds;
  final String status;
  final Future<void> Function(RouteApprovalMeal meal, bool value) onToggleMeal;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(day.date);
    final isPending = status.trim().toLowerCase() == 'pending';
    final canToggleDay = !isPending && !_isFuture(day.date);

    final sortedMeals = List<RouteApprovalMeal>.from(day.meals)
      ..sort(
        (a, b) =>
            _mealTypeRank(a.mealType).compareTo(_mealTypeRank(b.mealType)),
      );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Row(
          children: [
            Text(
              '${_weekday(day.date.weekday)}, ${_formatDate(day.date)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: Color(0xFF111827),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Hôm nay',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${day.meals.length} món',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          for (var index = 0; index < sortedMeals.length; index++) ...[
            _MealTile(
              meal: sortedMeals[index],
              plannedDate: sortedMeals[index].plannedDate ?? day.date,
              isUpdating: updatingMealIds.contains(sortedMeals[index].id),
              canToggle: canToggleDay,
              isPending: isPending,
              onChanged: (value) => onToggleMeal(sortedMeals[index], value),
            ),
            if (index < sortedMeals.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  static int _mealTypeRank(String mealType) {
    final t = mealType.trim().toLowerCase();
    if (t == 'breakfast' || t.contains('sáng')) return 1;
    if (t == 'lunch' || t.contains('trưa')) return 2;
    if (t == 'dinner' || t.contains('tối')) return 3;
    if (t == 'snack' || t.contains('phụ')) return 4;
    return 5;
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool _isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.isAfter(today);
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.meal,
    required this.plannedDate,
    required this.isUpdating,
    required this.canToggle,
    this.isPending = false,
    required this.onChanged,
  });

  final RouteApprovalMeal meal;
  final DateTime plannedDate;
  final bool isUpdating;
  final bool canToggle;
  final bool isPending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, borderColor) = _mealTypeColors(meal.mealType);
    final nutrition = formatNutritionFacts(
      quantityG: meal.quantityG,
      caloriesKcal: meal.calories,
      proteinG: meal.proteinG,
      carbsG: meal.carbsG,
      fatG: meal.fatG,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.restaurant, size: 17, color: AppColors.primary),
      ),
      title: Text(
        meal.name,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: meal.isCompleted
              ? Colors.grey.shade500
              : const Color(0xFF111827),
          decoration: meal.isCompleted
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Text(
                _mealTypeLabel(meal.mealType),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 10,
              runSpacing: 3,
              children: [
                _MealScheduleLabel(
                  icon: Icons.calendar_today_outlined,
                  text: 'Ngày ăn: ${mealPlannedDateLabel(plannedDate)}',
                ),
                _MealScheduleLabel(
                  icon: Icons.schedule_rounded,
                  text:
                      'Giờ ăn: ${mealScheduledTimeLabel(meal.scheduledTime, mealType: meal.mealType)}',
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '$nutrition\nChạm để xem chi tiết',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: Color(0xFFEA580C),
              ),
              const SizedBox(width: 3),
              Text(
                '${meal.calories} kcal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          if (isUpdating)
            const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            Tooltip(
              message: !canToggle
                  ? (isPending
                        ? 'Lộ trình đang chờ PT duyệt'
                        : 'Không thể đánh dấu ngày tương lai')
                  : (meal.isCompleted ? 'Đã ăn' : 'Đánh dấu đã ăn'),
              child: Checkbox(
                value: meal.isCompleted,
                onChanged: meal.id.isEmpty || !canToggle
                    ? null
                    : (value) {
                        if (value != null) onChanged(value);
                      },
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
      onTap: () => _openMealDetail(context),
    );
  }

  void _openMealDetail(BuildContext context) {
    final Widget? screen = (meal.foodId ?? '').isNotEmpty
        ? FoodDetailScreen(
            foodId: meal.foodId!,
            plannedQuantityG: meal.quantityG,
          )
        : (meal.recipeId ?? '').isNotEmpty
        ? RecipeDetailScreen(
            recipeId: meal.recipeId!,
            plannedQuantityG: meal.quantityG,
            plannedIngredients: meal.ingredients,
          )
        : null;
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  static (Color, Color, Color) _mealTypeColors(String type) {
    return switch (type.trim().toLowerCase()) {
      'breakfast' => (
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
        const Color(0xFFFFEDD5),
      ),
      'lunch' => (
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'dinner' => (
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
        const Color(0xFFBFDBFE),
      ),
      'snack' => (
        const Color(0xFFF5F3FF),
        const Color(0xFF7C3AED),
        const Color(0xFFDDD6FE),
      ),
      _ => (
        const Color(0xFFF3F4F6),
        AppColors.textSecondary,
        const Color(0xFFE5E7EB),
      ),
    };
  }
}

class _MealScheduleLabel extends StatelessWidget {
  const _MealScheduleLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _weekday(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Thứ Hai',
    DateTime.tuesday => 'Thứ Ba',
    DateTime.wednesday => 'Thứ Tư',
    DateTime.thursday => 'Thứ Năm',
    DateTime.friday => 'Thứ Sáu',
    DateTime.saturday => 'Thứ Bảy',
    DateTime.sunday => 'Chủ Nhật',
    _ => '',
  };
}

String _mealTypeLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'breakfast' => 'Bữa sáng',
    'lunch' => 'Bữa trưa',
    'dinner' => 'Bữa tối',
    'snack' => 'Bữa phụ',
    _ => value,
  };
}
