import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';
import '../utils/nutrition_warning_utils.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    super.key,
    required this.summary,
    this.title = 'Tiến độ mục tiêu',
  });

  final MealDaySummary? summary;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: const Text(
          'Chưa có dữ liệu dinh dưỡng cho ngày này.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    final s = summary!;
    final targetCalories = s.targetCalories.clamp(1, 100000).toDouble();
    final progress = (s.totalCalories / targetCalories).clamp(0, 1).toDouble();
    final goalPercent = s.goalCompletionPercent ??
        (targetCalories > 0 ? (s.totalCalories / targetCalories * 100) : null);
    final remaining = targetCalories - s.totalCalories;
    final warnings = NutritionWarningMessages.fromSummary(s);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...warnings.map(
              (msg) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                s.totalCalories.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                ' / ${targetCalories.toStringAsFixed(0)} kcal',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (goalPercent != null)
                Text(
                  '${goalPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.progressBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining >= 0
                ? 'Còn ${remaining.toStringAsFixed(0)} kcal'
                : 'Vượt ${(-remaining).toStringAsFixed(0)} kcal',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroChip('Protein', s.totalProteinG, s.targetProteinG),
              _macroChip('Carbs', s.totalCarbsG, s.targetCarbsG),
              _macroChip('Fat', s.totalFatG, s.targetFatG),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.progressBackground),
      );

  Widget _macroChip(String label, double current, double target) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
