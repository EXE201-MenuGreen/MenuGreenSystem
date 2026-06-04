import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

class CalorieTrendChart extends StatelessWidget {
  const CalorieTrendChart({
    super.key,
    required this.days,
    this.selectedDate,
    this.onDayTap,
  });

  final List<MealDaySummary> days;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDayTap;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Chưa có dữ liệu calo trong khoảng thời gian này.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final maxCalories = days
        .map((d) => d.totalCalories.clamp(0.0, double.infinity))
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxTarget = days
        .map((d) => d.targetCalories.clamp(1.0, double.infinity))
        .fold<double>(1, (a, b) => a > b ? a : b);
    final chartMax = (maxCalories > maxTarget ? maxCalories : maxTarget) * 1.1;
    if (chartMax <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calo theo ngày',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final parsed = DateTime.tryParse(day.date);
              final isSelected = parsed != null &&
                  selectedDate != null &&
                  parsed.year == selectedDate!.year &&
                  parsed.month == selectedDate!.month &&
                  parsed.day == selectedDate!.day;
              final barHeight = (day.totalCalories / chartMax * 80).clamp(4.0, 80.0);
              final barColor = day.hasWarning ? Colors.orange : AppColors.primary;

              return GestureDetector(
                onTap: parsed == null ? null : () => onDayTap?.call(parsed),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      day.totalCalories.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: isSelected ? 1 : 0.65),
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dayLabel(day.date),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _dayLabel(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day}/${date.month}';
  }
}
