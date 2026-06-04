import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../utils/nutrition_warning_utils.dart';

class CalendarHeatmapLegend extends StatelessWidget {
  const CalendarHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(level: HeatmapLevel.good, label: 'Đạt'),
          const SizedBox(width: 12),
          _LegendDot(level: HeatmapLevel.moderate, label: 'Gần'),
          const SizedBox(width: 12),
          _LegendDot(level: HeatmapLevel.poor, label: 'Lệch'),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: CalendarHeatmapStyle.backgroundForLevel(level),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class CalendarHeatmapStyle {
  CalendarHeatmapStyle._();

  static Color backgroundForLevel(HeatmapLevel level) {
    return switch (level) {
      HeatmapLevel.good => AppColors.primary.withValues(alpha: 0.35),
      HeatmapLevel.moderate => Colors.orange.withValues(alpha: 0.45),
      HeatmapLevel.poor => Colors.red.withValues(alpha: 0.35),
      HeatmapLevel.none => Colors.transparent,
    };
  }
}
