import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';

/// Screen thống kê meal plan
class MealPlanStatsScreen extends StatefulWidget {
  const MealPlanStatsScreen({super.key});

  @override
  State<MealPlanStatsScreen> createState() => _MealPlanStatsScreenState();
}

class _MealPlanStatsScreenState extends State<MealPlanStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MealPlanProvider>();
      provider.loadStreaks();
      provider.loadCompare();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê & Tiến độ'),
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadStreaks();
              await provider.loadCompare();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Streak section
                _buildStreakSection(provider),
                const SizedBox(height: 24),

                // Compare section
                _buildCompareSection(provider),
                const SizedBox(height: 24),

                // Weekly trends
                _buildWeeklyTrends(provider),
              ],
            ),
          );
        },
      ),
    );
  }

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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hoàn thành kế hoạch để bắt đầu streak!',
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
                  _buildStreakStat('Kỷ lục', '${streak.longestStreak}', Icons.emoji_events_outlined),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.progressBackground,
                  ),
                  _buildStreakStat('Tổng ngày', '${streak.totalCompletedDays}', Icons.check_circle_outline),
                  Container(
                    width: 1,
                    height: 30,
                    color: AppColors.progressBackground,
                  ),
                  _buildStreakStat('Trung bình', '${(streak.averageAdherence * 100).toStringAsFixed(0)}%', Icons.trending_up),
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
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompareSection(MealPlanProvider provider) {
    final compare = provider.compare;

    if (compare == null) {
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
            _buildCompareBar('Calo', compare.plannedCalories, compare.actualCalories, compare.caloriePercent, AppColors.primary),
            const SizedBox(height: 12),
            _buildCompareBar('Protein', compare.plannedProtein, compare.actualProtein, compare.proteinPercent, Colors.blue),
            const SizedBox(height: 12),
            _buildCompareBar('Carbs', compare.plannedCarbs, compare.actualCarbs, compare.carbsPercent, Colors.orange),
            const SizedBox(height: 12),
            _buildCompareBar('Fat', compare.plannedFat, compare.actualFat, compare.fatPercent, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareBar(String label, int planned, int actual, double percent, Color color) {
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
                color: percent >= 0.8 ? Colors.green : (percent >= 0.5 ? Colors.orange : Colors.red),
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

    if (compare == null || compare.weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'XU HƯỚNG 4 TUẦN',
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
    final color = percent >= 0.8 ? Colors.green : (percent >= 0.5 ? Colors.orange : Colors.red);

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
