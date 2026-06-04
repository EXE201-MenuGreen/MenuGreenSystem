import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/tracking/models/nutrition_models.dart';

void main() {
  test('MealDaySummary.fromJson parses goal and warning fields', () {
    final summary = MealDaySummary.fromJson({
      'date': '2026-06-04',
      'totalCalories': 1500,
      'totalProteinG': 80,
      'totalCarbsG': 180,
      'totalFatG': 50,
      'targetCalories': 2000,
      'targetProteinG': 120,
      'targetCarbsG': 220,
      'targetFatG': 60,
      'goalCompletionPercent': 75,
      'hasWarning': true,
      'mealLogs': [],
    });

    expect(summary.date, '2026-06-04');
    expect(summary.goalCompletionPercent, 75);
    expect(summary.hasWarning, isTrue);
  });

  test('MealLogItem.fromJson resolves displayName', () {
    final item = MealLogItem.fromJson({
      'id': 'a',
      'mealType': 'lunch',
      'quantityG': 150,
      'caloriesKcal': 300,
      'foodName': 'Phở bò',
      'displayName': 'Phở bò đặc biệt',
    });

    expect(item.displayName, 'Phở bò đặc biệt');
  });
}
