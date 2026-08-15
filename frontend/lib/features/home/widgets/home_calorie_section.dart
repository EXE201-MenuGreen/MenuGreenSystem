import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../meal_plan/widgets/calorie_progress_ring.dart';

class HomeCalorieSection extends StatelessWidget {
  const HomeCalorieSection({
    super.key,
    required this.totalCalories,
    required this.targetCalories,
    required this.protein,
    required this.targetProtein,
    required this.carbs,
    required this.targetCarbs,
    required this.fat,
    required this.targetFat,
    this.onTap,
  });

  final int totalCalories;
  final int targetCalories;
  final int protein;
  final int targetProtein;
  final int carbs;
  final int targetCarbs;
  final int fat;
  final int targetFat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ringSize = context.valueForDevice(
      phone: 120.0,
      tablet: 140.0,
      desktop: 160.0,
    );
    final strokeWidth = context.valueForDevice(
      phone: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );
    final contentPaddingH = context.valueForDevice(
      phone: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );
    final contentPaddingV = context.valueForDevice(
      phone: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
    final borderRadius = context.valueForDevice(
      phone: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
    final headerPaddingH = context.valueForDevice(
      phone: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );
    final headerPaddingV = context.valueForDevice(
      phone: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
    final iconSize = context.valueForDevice(
      phone: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );
    final sectionTitleFontSize = context.valueForDevice(
      phone: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
    final macroRowSpacing = context.valueForDevice(
      phone: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );
    final betweenRingAndMacro = context.valueForDevice(
      phone: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
    final bottomSpacing = context.valueForDevice(
      phone: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with soft gradient
          Container(
            padding: EdgeInsets.symmetric(horizontal: headerPaddingH, vertical: headerPaddingV),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.primary,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tiến độ dinh dưỡng',
                    style: beVietnamPro(
                      fontSize: sectionTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chi tiết',
                          style: beVietnamPro(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(contentPaddingH, contentPaddingV, contentPaddingH, contentPaddingV),
            child: Column(
              children: [
                Row(
                  children: [
                    // Calorie Ring
                    CalorieProgressRing(
                      current: totalCalories,
                      target: targetCalories,
                      size: ringSize,
                      strokeWidth: strokeWidth,
                    ),
                    SizedBox(width: betweenRingAndMacro),
                    // Macros
                    Expanded(
                      child: Column(
                        children: [
                          _MacroRow(
                            label: 'Protein',
                            current: protein,
                            target: targetProtein,
                            color: const Color(0xFF2563EB), // Modern Royal Blue
                            unit: 'g',
                          ),
                          SizedBox(height: macroRowSpacing),
                          _MacroRow(
                            label: 'Carb',
                            current: carbs,
                            target: targetCarbs,
                            color: const Color(0xFFF59E0B), // Warm Amber
                            unit: 'g',
                          ),
                          SizedBox(height: macroRowSpacing),
                          _MacroRow(
                            label: 'Chất béo',
                            current: fat,
                            target: targetFat,
                            color: const Color(0xFFF43F5E), // Coral Rose
                            unit: 'g',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: bottomSpacing),
                // Remaining calories bar
                _RemainingCaloriesBar(
                  current: totalCalories,
                  target: targetCalories,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
  });

  final String label;
  final int current;
  final int target;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final labelFontSize = context.valueForDevice(
      phone: 12.0,
      tablet: 13.0,
      desktop: 14.0,
    );
    final valueFontSize = context.valueForDevice(
      phone: 12.0,
      tablet: 13.0,
      desktop: 14.0,
    );
    final indicatorSize = context.valueForDevice(
      phone: 8.0,
      tablet: 9.0,
      desktop: 10.0,
    );
    final progressHeight = context.valueForDevice(
      phone: 8.0,
      tablet: 9.0,
      desktop: 10.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: context.valueForDevice(phone: 8.0, tablet: 10.0, desktop: 10.0)),
                Text(
                  label,
                  style: beVietnamPro(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              '${current}g / ${target}g',
              style: beVietnamPro(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        SizedBox(height: context.valueForDevice(phone: 6.0, tablet: 8.0, desktop: 8.0)),
        ClipRRect(
          borderRadius: BorderRadius.circular(10), // Pill Shape
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.progressBackground.withValues(alpha: 0.6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: progressHeight,
          ),
        ),
      ],
    );
  }
}

class _RemainingCaloriesBar extends StatelessWidget {
  const _RemainingCaloriesBar({
    required this.current,
    required this.target,
  });

  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final remaining = target - current;
    final isOverBudget = remaining < 0;
    final color = isOverBudget ? const Color(0xFFEF4444) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOverBudget ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverBudget ? 'Đã vượt quá' : 'Hôm nay còn lại',
                  style: beVietnamPro(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${remaining.abs()} kcal',
                  style: beVietnamPro(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mục tiêu',
                style: beVietnamPro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$target kcal',
                style: beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
