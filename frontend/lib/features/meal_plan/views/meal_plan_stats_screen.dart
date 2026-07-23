import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/safe_date_picker.dart';
import '../models/meal_plan_responses.dart';
import '../models/meal_plan_stats_period.dart';
import '../providers/meal_plan_provider.dart';

/// Screen thống kê meal plan
class MealPlanStatsScreen extends StatefulWidget {
  const MealPlanStatsScreen({super.key});

  @override
  State<MealPlanStatsScreen> createState() => _MealPlanStatsScreenState();
}

class _MealPlanStatsScreenState extends State<MealPlanStatsScreen> {
  MealPlanStatsPeriod _selectedPeriod = MealPlanStatsPeriod.day;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  ({DateTime from, DateTime to}) get _selectedRange {
    return mealPlanStatsRangeFor(
      _selectedPeriod,
      _selectedDate,
      currentDate: DateTime.now(),
    );
  }

  Future<void> _loadStats() async {
    final provider = context.read<MealPlanProvider>();
    final range = _selectedRange;
    await Future.wait([
      provider.loadStreaks(),
      provider.loadCompare(from: range.from, to: range.to),
    ]);
  }

  Future<void> _selectPeriod(MealPlanStatsPeriod period) async {
    if (period == _selectedPeriod) return;
    setState(() => _selectedPeriod = period);
    final range = _selectedRange;
    await context.read<MealPlanProvider>().loadCompare(
      from: range.from,
      to: range.to,
    );
  }

  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());
    final pickedDate = await showSafeDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Chọn ngày xem thống kê',
    );

    if (!mounted || pickedDate == null) return;

    final normalizedDate = _dateOnly(pickedDate);
    if (normalizedDate == _selectedDate) return;

    setState(() => _selectedDate = normalizedDate);
    final range = _selectedRange;
    await context.read<MealPlanProvider>().loadCompare(
      from: range.from,
      to: range.to,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê & Tiến độ')),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadStats();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Streak section
                _buildStreakSection(provider),
                const SizedBox(height: 24),

                // Date range selector
                _buildPeriodSelector(provider),
                const SizedBox(height: 12),

                // Compare section
                _buildCompareSection(provider),
                const SizedBox(height: 24),

                // Weekly trends
                if (_selectedPeriod == MealPlanStatsPeriod.month)
                  _buildWeeklyTrends(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(MealPlanProvider provider) {
    final range = _selectedRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THỜI GIAN THEO DÕI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<MealPlanStatsPeriod>(
            segments: const [
              ButtonSegment(
                value: MealPlanStatsPeriod.day,
                label: Text('Ngày'),
              ),
              ButtonSegment(
                value: MealPlanStatsPeriod.week,
                label: Text('Tuần'),
              ),
              ButtonSegment(
                value: MealPlanStatsPeriod.month,
                label: Text('Tháng'),
              ),
            ],
            selected: {_selectedPeriod},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              if (!provider.isLoadingCompare) {
                _selectPeriod(selection.first);
              }
            },
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          button: true,
          enabled: !provider.isLoadingCompare,
          label: 'Chọn ngày xem thống kê',
          value: _formatRange(range.from, range.to),
          child: InkWell(
            onTap: provider.isLoadingCompare ? null : _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.progressBackground.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatRange(range.from, range.to),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (provider.isLoadingCompare) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }

  String _formatRange(DateTime from, DateTime to) {
    String format(DateTime value) =>
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';

    if (from == to) {
      final today = _dateOnly(DateTime.now());
      if (to == today) return 'Hôm nay, ${format(to)}';
      if (to == today.subtract(const Duration(days: 1))) {
        return 'Hôm qua, ${format(to)}';
      }
      return 'Ngày ${format(to)}';
    }
    return '${format(from)} - ${format(to)}';
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Widget _buildStreakSection(MealPlanProvider provider) {
    final streak = provider.streaks;

    if (streak == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có streak',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tạo kế hoạch hôm nay để bắt đầu streak!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 32,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  'STREAK',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${streak.currentStreak}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                height: 1,
              ),
            ),
            const Text(
              'NGÀY LIÊN TIẾP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.progressBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakStat(
                    'Kỷ lục',
                    '${streak.longestStreak}',
                    Icons.emoji_events_outlined,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.progressBackground,
                  ),
                  _buildStreakStat(
                    'Tổng ngày',
                    '${streak.totalCompletedDays}',
                    Icons.check_circle_outline,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.progressBackground,
                  ),
                  _buildStreakStat(
                    'Trung bình',
                    '${(streak.averageAdherence * 100).toStringAsFixed(0)}%',
                    Icons.trending_up,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCompareSection(MealPlanProvider provider) {
    final compare = provider.compare;

    if (compare == null) {
      if (provider.isLoadingCompare) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có dữ liệu so sánh',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final caloPercent = compare.plannedCalories > 0
        ? compare.actualCalories / compare.plannedCalories
        : 0.0;
    final proteinPercent = compare.plannedProtein > 0
        ? compare.actualProtein / compare.plannedProtein
        : 0.0;
    final carbsPercent = compare.plannedCarbs > 0
        ? compare.actualCarbs / compare.plannedCarbs
        : 0.0;
    final fatPercent = compare.plannedFat > 0
        ? compare.actualFat / compare.plannedFat
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SO SÁNH KẾ HOẠCH & THỰC TẾ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            _buildCompareBar(
              'Calo',
              compare.plannedCalories,
              compare.actualCalories,
              caloPercent,
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildCompareBar(
              'Protein',
              compare.plannedProtein,
              compare.actualProtein,
              proteinPercent,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildCompareBar(
              'Carbs',
              compare.plannedCarbs,
              compare.actualCarbs,
              carbsPercent,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildCompareBar(
              'Fat',
              compare.plannedFat,
              compare.actualFat,
              fatPercent,
              Colors.purple,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.progressBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${compare.completedDays}/${compare.totalDays} ngày hoàn thành kế hoạch',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareBar(
    String label,
    int planned,
    int actual,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '$actual/$planned (${(percent * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: percent >= 0.8
                    ? Colors.green
                    : (percent >= 0.5 ? Colors.orange : Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            backgroundColor: AppColors.progressBackground,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrends(MealPlanProvider provider) {
    final compare = provider.compare;

    if (compare == null || compare.weeklyData.length <= 1) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'XU HƯỚNG TRONG THÁNG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            ...compare.weeklyData.map((week) => _buildWeekBar(week)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekBar(WeekCompare week) {
    final percent = week.percent.clamp(0.0, 1.0).toDouble();
    final color = percent >= 0.8
        ? Colors.green
        : (percent >= 0.5 ? Colors.orange : Colors.red);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuần ${week.weekNumber}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: AppColors.progressBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
