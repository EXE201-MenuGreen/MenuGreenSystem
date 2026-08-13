import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum CalorieAdjustmentMode { below, balanced, above }

@visibleForTesting
int calorieAdjustmentTotal({
  required int targetCalories,
  required CalorieAdjustmentMode mode,
  required int percentage,
}) {
  final safePercentage = percentage.clamp(0, 50);
  return switch (mode) {
    CalorieAdjustmentMode.below =>
      (targetCalories * (100 - safePercentage) / 100).round(),
    CalorieAdjustmentMode.balanced => targetCalories,
    CalorieAdjustmentMode.above =>
      (targetCalories * (100 + safePercentage) / 100).round(),
  };
}

Future<int?> showCalorieAdjustmentPicker({
  required BuildContext context,
  required int targetCalories,
}) {
  var mode = CalorieAdjustmentMode.balanced;
  var percentage = 10;

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final desiredCalories = calorieAdjustmentTotal(
            targetCalories: targetCalories,
            mode: mode,
            percentage: percentage,
          );
          final comparisonLabel = switch (mode) {
            CalorieAdjustmentMode.below => 'Thấp hơn mục tiêu',
            CalorieAdjustmentMode.balanced => 'Cân bằng đúng mục tiêu',
            CalorieAdjustmentMode.above => 'Cao hơn mục tiêu',
          };

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chọn mức kcal mong muốn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mốc dinh dưỡng vẫn giữ ở $targetCalories kcal. '
                    'Chỉ khẩu phần các món được thay đổi.',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<CalorieAdjustmentMode>(
                    segments: const [
                      ButtonSegment(
                        value: CalorieAdjustmentMode.below,
                        icon: Icon(Icons.south_rounded),
                        label: Text('Thấp hơn'),
                      ),
                      ButtonSegment(
                        value: CalorieAdjustmentMode.balanced,
                        icon: Icon(Icons.balance_rounded),
                        label: Text('Cân bằng'),
                      ),
                      ButtonSegment(
                        value: CalorieAdjustmentMode.above,
                        icon: Icon(Icons.north_rounded),
                        label: Text('Cao hơn'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      setSheetState(() => mode = selection.first);
                    },
                  ),
                  if (mode != CalorieAdjustmentMode.balanced) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'Mức chênh lệch',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: percentage.toDouble(),
                      min: 5,
                      max: 20,
                      divisions: 15,
                      label: '$percentage%',
                      onChanged: (value) {
                        setSheetState(() => percentage = value.round());
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            comparisonLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '$desiredCalories kcal',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.pop(sheetContext, desiredCalories),
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: Text('Áp dụng $desiredCalories kcal'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
