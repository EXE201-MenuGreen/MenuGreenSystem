import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class DailyCalorieBalanceCard extends StatelessWidget {
  const DailyCalorieBalanceCard({
    super.key,
    required this.totalCalories,
    required this.targetCalories,
    required this.mealCount,
    required this.onAutoBalance,
    this.dateLabel,
    this.canAutoBalance = true,
    this.lockedLabel = 'Đã khóa',
    this.width,
  });

  final int totalCalories;
  final int targetCalories;
  final int mealCount;
  final VoidCallback? onAutoBalance;
  final String? dateLabel;
  final bool canAutoBalance;
  final String lockedLabel;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final difference = totalCalories - targetCalories;
    final isExact = difference == 0;
    final isOver = difference > 0;
    final statusColor = isExact
        ? const Color(0xFF047857)
        : isOver
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final statusBackground = isExact
        ? const Color(0xFFECFDF5)
        : isOver
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final status = isExact
        ? 'Đạt mục tiêu'
        : isOver
        ? 'Vượt ${difference.abs()} kcal'
        : 'Thiếu ${difference.abs()} kcal';
    final suggestedPercent = totalCalories <= 0
        ? 0
        : (((targetCalories / totalCalories) - 1).abs() * 100).round();
    final suggestedAction = isOver ? 'giảm' : 'tăng';
    final progress = targetCalories <= 0
        ? 0.0
        : (totalCalories / targetCalories).clamp(0.0, 1.0);
    final enabled =
        canAutoBalance &&
        !isExact &&
        totalCalories > 0 &&
        targetCalories > 0 &&
        onAutoBalance != null;

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dateLabel != null)
                Expanded(
                  child: Text(
                    dateLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              else
                const Spacer(),
              Text(
                '$mealCount/4 bữa',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$totalCalories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
                TextSpan(
                  text: ' / $targetCalories kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          if (!isExact && totalCalories > 0) ...[
            Text(
              'Gợi ý: $suggestedAction khẩu phần khoảng $suggestedPercent%',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: enabled ? onAutoBalance : null,
                icon: Icon(
                  canAutoBalance
                      ? Icons.auto_fix_high_rounded
                      : Icons.lock_outline_rounded,
                  size: 15,
                ),
                label: Text(canAutoBalance ? 'Tự chỉnh' : lockedLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
