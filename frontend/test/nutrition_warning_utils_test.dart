import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/tracking/models/nutrition_models.dart';
import 'package:frontend/features/tracking/utils/nutrition_warning_utils.dart';

void main() {
  group('NutritionHeatmapColors', () {
    test('levelForPercent maps ranges correctly', () {
      expect(NutritionHeatmapColors.levelForPercent(null), HeatmapLevel.none);
      expect(NutritionHeatmapColors.levelForPercent(95), HeatmapLevel.good);
      expect(NutritionHeatmapColors.levelForPercent(70), HeatmapLevel.moderate);
      expect(NutritionHeatmapColors.levelForPercent(130), HeatmapLevel.moderate);
      expect(NutritionHeatmapColors.levelForPercent(50), HeatmapLevel.poor);
    });
  });

  group('NutritionWarningMessages', () {
    test('includes macro warnings when deviation exceeds threshold', () {
      final summary = MealDaySummary(
        date: '2026-06-04',
        totalCalories: 2000,
        totalProteinG: 50,
        totalCarbsG: 200,
        totalFatG: 40,
        targetCalories: 2000,
        targetProteinG: 120,
        targetCarbsG: 220,
        targetFatG: 60,
        mealLogs: const [],
        hasWarning: false,
      );

      final messages = NutritionWarningMessages.fromSummary(summary);
      expect(messages.any((m) => m.contains('Protein')), isTrue);
    });
  });
}
