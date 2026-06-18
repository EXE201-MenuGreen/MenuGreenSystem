import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/weekly_plan_day_card.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  final _provider = RecommendationProvider();

  late DateTime _startDate;
  late DateTime _endDate;
  int _dailyTargetCalories = 2000;
  bool _excludeUserAllergies = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now;
    _endDate = now.add(const Duration(days: 6));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generatePlan() async {
    await _provider.generateWeeklyPlan(
      startDate: _startDate,
      endDate: _endDate,
      dailyTargetCalories: _dailyTargetCalories,
      excludeUserAllergies: _excludeUserAllergies,
    );

    if (mounted && _provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_provider.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thực đơn tuần'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: _provider.weeklyPlan == null
          ? _buildConfigForm()
          : _buildPlanResult(),
      floatingActionButton: _provider.weeklyPlan != null
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _provider.clearWeeklyPlan();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tạo lại'),
            )
          : null,
    );
  }

  Widget _buildConfigForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời gian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calories mục tiêu / ngày',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_dailyTargetCalories kcal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Slider(
                  value: _dailyTargetCalories.toDouble(),
                  min: 1200,
                  max: 3000,
                  divisions: 18,
                  label: '$_dailyTargetCalories kcal',
                  onChanged: (value) {
                    setState(() {
                      _dailyTargetCalories = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1200', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text('3000', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: SwitchListTile(
            title: const Text('Loại trừ dị ứng'),
            subtitle: const Text('Tự động loại bỏ các món có thể gây dị ứng'),
            value: _excludeUserAllergies,
            onChanged: (value) {
              setState(() {
                _excludeUserAllergies = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _provider.isGenerating ? null : _generatePlan,
            icon: _provider.isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_provider.isGenerating ? 'Đang tạo...' : 'Tạo thực đơn tuần'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanResult() {
    final plan = _provider.weeklyPlan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(plan.startDate)} - ${_formatDate(plan.endDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (plan.dailyTargetCalories != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Mục tiêu: ${plan.dailyTargetCalories} kcal / ngày',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...plan.days.map((day) => WeeklyPlanDayCard(day: day)),
        const SizedBox(height: 24),
        if (plan.days.isNotEmpty) _buildSummary(plan),
      ],
    );
  }

  Widget _buildSummary(WeeklyPlanResponse plan) {
    final totalMeals = plan.days.fold<int>(0, (sum, day) => sum + day.meals.length);
    final avgCalories = plan.days.isEmpty
        ? 0
        : plan.days.fold<int>(0, (sum, day) => sum + day.totalCalories) ~/ plan.days.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng kết',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(Icons.restaurant_menu, 'Tổng số bữa ăn', '$totalMeals bữa'),
            _buildSummaryRow(
              Icons.local_fire_department,
              'Calories trung bình / ngày',
              '$avgCalories kcal',
            ),
            _buildSummaryRow(
              Icons.calendar_today,
              'Số ngày',
              '${plan.days.length} ngày',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}';
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
