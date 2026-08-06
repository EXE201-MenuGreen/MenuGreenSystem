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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DashboardRange.values.map((range) {
          final isSelected = range == selected;
          return GestureDetector(
            onTap: () => onChanged(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
