import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../utils/nutrition_warning_utils.dart';

class CalendarHeatmapLegend extends StatelessWidget {
  const CalendarHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _LegendDot(level: HeatmapLevel.good, label: 'Đạt mục tiêu'),
          SizedBox(width: 14),
          _LegendDot(level: HeatmapLevel.moderate, label: 'Gần đạt'),
          SizedBox(width: 14),
          _LegendDot(level: HeatmapLevel.poor, label: 'Chênh lệch'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.level, required this.label});

  final HeatmapLevel level;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: CalendarHeatmapStyle.dotColorForLevel(level),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class CalendarHeatmapStyle {
  CalendarHeatmapStyle._();

  static Color backgroundForLevel(HeatmapLevel level) {
    return switch (level) {
      HeatmapLevel.good => AppColors.primary.withValues(alpha: 0.18),
      HeatmapLevel.moderate => Colors.amber.withValues(alpha: 0.25),
      HeatmapLevel.poor => const Color(0xFFE11D48).withValues(alpha: 0.2),
      HeatmapLevel.none => Colors.transparent,
    };
  }

  static Color dotColorForLevel(HeatmapLevel level) {
    return switch (level) {
      HeatmapLevel.good => AppColors.primary,
      HeatmapLevel.moderate => const Color(0xFFD97706),
      HeatmapLevel.poor => const Color(0xFFE11D48),
      HeatmapLevel.none => Colors.transparent,
    };
  }
}
