import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';
import 'meal_plan_detail_screen.dart';

/// Screen lich meal plan
class MealPlanCalendarScreen extends StatefulWidget {
  const MealPlanCalendarScreen({super.key});

  @override
  State<MealPlanCalendarScreen> createState() => _MealPlanCalendarScreenState();
}

class _MealPlanCalendarScreenState extends State<MealPlanCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  final Map<DateTime, DayPlanSummary> _daySummaries = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lich ke hoach'),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('Hom nay'),
          ),
        ],
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildMonthHeader(),
              Expanded(
                flex: 3,
                child: _buildCalendarGrid(provider),
              ),
              if (_selectedDate != null)
                Expanded(
                  flex: 2,
                  child: _buildDayDetails(provider),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            _formatMonth(_currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(MealPlanProvider provider) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    final days = <Widget>[];

    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    for (final day in weekdays) {
      days.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    for (var i = 1; i < startingWeekday; i++) {
      days.add(const SizedBox());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = _isToday(date);
      final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
      final isFuture = date.isAfter(DateTime.now());
      final summary = _daySummaries[DateTime(date.year, date.month, date.day)];

      days.add(
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedDate = date);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (isFuture ? AppColors.textSecondary : AppColors.textDark),
                    ),
                  ),
                  if (!isFuture && summary != null) ...[
                    const SizedBox(height: 2),
                    _buildDayIndicator(summary.adherencePercent),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.progressBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('>=80%', Colors.green),
                _buildLegendItem('50-80%', Colors.orange),
                _buildLegendItem('<50%', Colors.red),
                _buildLegendItem('Chua co', Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: days,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(double adherencePercent) {
    Color color;
    if (adherencePercent >= 0.8) {
      color = Colors.green;
    } else if (adherencePercent >= 0.5) {
      color = Colors.orange;
    } else if (adherencePercent > 0) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDayDetails(MealPlanProvider provider) {
    final summary = _selectedDate != null
        ? _daySummaries[DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)]
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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
                    _formatDate(_selectedDate!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getDaySummaryText(summary),
                    style: TextStyle(
                      fontSize: 13,
                      color: _getSummaryColor(summary),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedDate = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (summary != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    label: 'Calo',
                    value: '${summary.actualCalories}/${summary.plannedCalories}',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Bua an',
                    value: '${summary.completedMeals}/${summary.totalMeals}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    label: 'Adherence',
                    value: '${(summary.adherencePercent * 100).toStringAsFixed(0)}%',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 32,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chua co du lieu cho ngay nay',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _viewDayDetail(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Xem chi tiet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getDaySummaryText(DayPlanSummary? summary) {
    if (summary == null) return 'Khong co ke hoach';
    if (summary.adherencePercent >= 0.8) return 'Hoan thanh tot';
    if (summary.adherencePercent >= 0.5) return 'Can cai thien';
    if (summary.adherencePercent > 0) return 'Chua dat muc tieu';
    return 'Chua co du lieu';
  }

  Color _getSummaryColor(DayPlanSummary? summary) {
    if (summary == null) return AppColors.textSecondary;
    if (summary.adherencePercent >= 0.8) return Colors.green;
    if (summary.adherencePercent >= 0.5) return Colors.orange;
    if (summary.adherencePercent > 0) return Colors.red;
    return AppColors.textSecondary;
  }

  void _viewDayDetail(BuildContext context, MealPlanProvider provider) {
    final plans = provider.plans;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong co ke hoach nao')),
      );
      return;
    }

    final plan = plans.firstWhere(
      (p) => p.isActive,
      orElse: () => plans.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealPlanDetailScreen(
          planId: plan.id,
          initialDate: _selectedDate,
        ),
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Thang 1', 'Thang 2', 'Thang 3', 'Thang 4',
      'Thang 5', 'Thang 6', 'Thang 7', 'Thang 8',
      'Thang 9', 'Thang 10', 'Thang 11', 'Thang 12'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Thu 2', 'Thu 3', 'Thu 4', 'Thu 5', 'Thu 6', 'Thu 7', 'Chu nhat'];
    return '${weekdays[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }
}
