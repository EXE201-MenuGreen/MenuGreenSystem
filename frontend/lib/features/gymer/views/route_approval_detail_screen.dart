import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../models/route_approval_detail.dart';

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
      var detail = RouteApprovalDetail.fromJson(raw);
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

    final plans = await Future.wait(dates.map(MealPlanRepository().getByDate));
    final snapshotDays = {
      for (final day in detail.days) _dateKey(day.date): day,
    };
    final resolvedDays = <RouteApprovalDay>[];

    for (var index = 0; index < plans.length; index++) {
      final date = dates[index];
      final plan = plans[index];
      if (plan != null && plan.items.isNotEmpty) {
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
                    isCompleted: item.isCompleted,
                    foodId: item.foodId,
                    recipeId: item.recipeId,
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
      await MealPlanRepository().toggleItem(meal.id, value);
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
                            ? item.copyWith(isCompleted: value)
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
              : '${_isRouteApproval(_detail!) ? 'Lộ trình Ngày' : 'Lộ trình Tuần'} '
                    '${_formatDate(_detail!.days.isNotEmpty ? _detail!.days.first.date : _detail!.weekStartDate)}',
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
            child: Text(
              detail.ptComment.trim().isEmpty
                  ? 'PT chưa để lại ghi chú.'
                  : detail.ptComment.trim(),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: detail.ptComment.trim().isEmpty
                    ? Colors.grey.shade500
                    : const Color(0xFF374151),
                fontStyle: detail.ptComment.trim().isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Bữa ăn và món ăn',
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
                          onToggleMeal: _toggleMeal,
                        ),
                        if (index < populatedDays.length - 1)
                          const Divider(height: 16),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_box_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đánh dấu món đã ăn để PT theo dõi tiến độ của bạn.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
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
    final isDaily = detail.requestType.trim().toLowerCase() == 'routeapproval';
    final displayDate = isDaily
        ? (detail.days.isNotEmpty
              ? detail.days.first.date
              : detail.weekStartDate)
        : detail.weekStartDate;

    final period = '${isDaily ? 'Ngày' : 'Tuần'} ${_formatDate(displayDate)}';
    final description = detail.studentNote.trim().isEmpty
        ? 'Lộ trình dinh dưỡng gửi PT duyệt.'
        : detail.studentNote.trim();
    final targets = <Widget>[
      if (detail.configuredCalorieTarget != null)
        _TargetRow(
          icon: Icons.local_fire_department_rounded,
          label: 'Calories/ngày',
          value: '${detail.configuredCalorieTarget} kcal',
          color: const Color(0xFFE65100),
        ),
      if (detail.configuredMinCalories != null)
        _TargetRow(
          icon: Icons.vertical_align_bottom,
          label: 'Kcal món tối thiểu',
          value: '${detail.configuredMinCalories} kcal',
          color: const Color(0xFF6D4C41),
        ),
      if (detail.configuredMaxCalories != null)
        _TargetRow(
          icon: Icons.vertical_align_top,
          label: 'Kcal món tối đa',
          value: '${detail.configuredMaxCalories} kcal',
          color: const Color(0xFFAD1457),
        ),
      if (detail.targetProteinG != null)
        _TargetRow(
          icon: Icons.fitness_center_rounded,
          label: 'Protein',
          value: '${detail.targetProteinG} g',
          color: AppColors.primary,
        ),
      if (detail.targetCarbsG != null)
        _TargetRow(
          icon: Icons.bakery_dining_rounded,
          label: 'Carbs',
          value: '${detail.targetCarbsG} g',
          color: const Color(0xFF8D6E63),
        ),
      if (detail.targetFatG != null)
        _TargetRow(
          icon: Icons.water_drop_outlined,
          label: 'Fat',
          value: '${detail.targetFatG} g',
          color: const Color(0xFFFFA000),
        ),
    ];

    return Column(
      children: [
        _DetailSection(
          title: 'Tổng quan',
          child: Column(
            children: [
              _InfoRow('Mô tả', description),
              _InfoRow('Loại cấu hình', isDaily ? 'Ngày' : 'Tuần'),
              _InfoRow('Thời gian', period),
              _InfoRow('Thời lượng', isDaily ? '1 ngày' : '1 tuần'),
              _InfoRow('Trạng thái', _statusLabel(detail.status)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Mục tiêu dinh dưỡng',
          child: targets.isEmpty
              ? const Text(
                  'Chưa có mục tiêu dinh dưỡng cho ngày này.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(children: targets),
        ),
      ],
    );
  }

  static String _statusLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'pending' => 'Chờ PT phản hồi',
      'reviewed' => 'Đã duyệt',
      'applied' => 'Đã áp dụng',
      'rejected' => 'Đã từ chối',
      _ => value,
    };
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
    required this.onToggleMeal,
  });

  final RouteApprovalDay day;
  final Set<String> updatingMealIds;
  final Future<void> Function(RouteApprovalMeal meal, bool value) onToggleMeal;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(day.date);
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
              isUpdating: updatingMealIds.contains(sortedMeals[index].id),
              canToggle: !_isFuture(day.date),
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
    required this.isUpdating,
    required this.canToggle,
    required this.onChanged,
  });

  final RouteApprovalMeal meal;
  final bool isUpdating;
  final bool canToggle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, borderColor) = _mealTypeColors(meal.mealType);
    final nutrition = <String>[
      '${meal.calories} kcal',
      if (meal.proteinG != null) 'P ${meal.proteinG}g',
      if (meal.carbsG != null) 'C ${meal.carbsG}g',
      if (meal.fatG != null) 'F ${meal.fatG}g',
    ].join(' · ');

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
            Text(
              '$nutrition · Chạm để xem chi tiết',
              maxLines: 2,
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
              message: meal.isCompleted ? 'Đã ăn' : 'Đánh dấu đã ăn',
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
        ? FoodDetailScreen(foodId: meal.foodId!)
        : (meal.recipeId ?? '').isNotEmpty
        ? RecipeDetailScreen(recipeId: meal.recipeId!)
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
