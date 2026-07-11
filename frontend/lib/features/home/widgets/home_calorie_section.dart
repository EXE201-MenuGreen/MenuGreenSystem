import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tiến độ dinh dưỡng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
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
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Calorie Ring
                    CalorieProgressRing(
                      current: totalCalories,
                      target: targetCalories,
                      size: 120,
                      strokeWidth: 12,
                    ),
                    const SizedBox(width: 24),
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
                          const SizedBox(height: 14),
                          _MacroRow(
                            label: 'Carbs',
                            current: carbs,
                            target: targetCarbs,
                            color: const Color(0xFFF59E0B), // Warm Amber
                            unit: 'g',
                          ),
                          const SizedBox(height: 14),
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
                const SizedBox(height: 20),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              '${current}g / ${target}g',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10), // Pill Shape
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.progressBackground.withValues(alpha: 0.6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
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
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${remaining.abs()} kcal',
                  style: GoogleFonts.beVietnamPro(
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
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$target kcal',
                style: GoogleFonts.beVietnamPro(
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
