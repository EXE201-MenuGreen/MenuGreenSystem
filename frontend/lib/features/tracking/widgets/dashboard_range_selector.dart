import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

enum DashboardRange { day, week, month }

extension DashboardRangeX on DashboardRange {
  String get apiValue => name;

  String get label => switch (this) {
        DashboardRange.day => 'Ngày',
        DashboardRange.week => 'Tuần',
        DashboardRange.month => 'Tháng',
      };
}

class DashboardRangeSelector extends StatelessWidget {
  const DashboardRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DashboardRange selected;
  final ValueChanged<DashboardRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DashboardRange.values.map((range) {
        final isSelected = range == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(range),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.progressBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
