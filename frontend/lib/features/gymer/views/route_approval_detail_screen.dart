import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../advanced/repositories/advanced_repository.dart';
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
    final start = detail.weekStartDate;
    if (start.millisecondsSinceEpoch == 0) return detail;

    final plans = await Future.wait(
      List.generate(
        7,
        (index) =>
            MealPlanRepository().getByDate(start.add(Duration(days: index))),
      ),
    );
    final snapshotDays = {
      for (final day in detail.days) _dateKey(day.date): day,
    };
    final resolvedDays = <RouteApprovalDay>[];

    for (var index = 0; index < plans.length; index++) {
      final date = start.add(Duration(days: index));
      final plan = plans[index];
      if (plan != null && plan.items.isNotEmpty) {
        resolvedDays.add(
          RouteApprovalDay(
            date: date,
            meals: plan.items
                .map(
                  (item) => RouteApprovalMeal(
                    mealType: item.mealType,
                    name: item.displayName,
                    calories: item.targetCalories,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Chi tiết lộ trình'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
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
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(detail: detail),
          const SizedBox(height: 16),
          const Text(
            'Nhận xét của PT',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              detail.ptComment.trim().isEmpty
                  ? 'PT chưa để lại ghi chú.'
                  : detail.ptComment.trim(),
              style: const TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bữa ăn và món ăn trong lộ trình',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (populatedDays.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Lộ trình này chưa có món ăn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (final day in populatedDays) ...[
              _DayMealsCard(day: day),
              const SizedBox(height: 10),
            ],
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
    final totalMeals = detail.days.fold<int>(
      0,
      (total, day) => total + day.meals.length,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuần ${_formatDate(detail.weekStartDate)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(icon: Icons.restaurant_menu, text: '$totalMeals món'),
              if (detail.suggestedCalorieTarget != null)
                _MetricChip(
                  icon: Icons.local_fire_department,
                  text: '${detail.suggestedCalorieTarget} kcal',
                ),
              if (detail.suggestedProteinTarget != null)
                _MetricChip(
                  icon: Icons.fitness_center,
                  text: '${detail.suggestedProteinTarget}g protein',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DayMealsCard extends StatelessWidget {
  const _DayMealsCard({required this.day});

  final RouteApprovalDay day;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: _isToday(day.date),
        title: Text(
          '${_weekday(day.date.weekday)}, ${_formatDate(day.date)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${day.meals.length} món'),
        children: [
          for (var index = 0; index < day.meals.length; index++) ...[
            _MealTile(meal: day.meals[index]),
            if (index < day.meals.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final RouteApprovalMeal meal;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        meal.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_mealTypeLabel(meal.mealType)),
      trailing: Text(
        '${meal.calories} kcal',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
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
