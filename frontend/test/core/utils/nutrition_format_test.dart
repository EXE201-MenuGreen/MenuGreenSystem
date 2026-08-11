import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/nutrition_format.dart';

void main() {
  group('formatNutritionFacts', () {
    test('shows serving, calories and all macros', () {
      expect(
        formatNutritionFacts(
          quantityG: 150,
          caloriesKcal: 576,
          proteinG: 28,
          carbsG: 27,
          fatG: 8,
        ),
        '150 g · 576 kcal · P 28 g · C 27 g · F 8 g',
      );
    });

    test('keeps missing values visible instead of silently hiding metrics', () {
      expect(
        formatNutritionFacts(
          quantityG: null,
          caloriesKcal: 510,
          proteinG: null,
          carbsG: 55.5,
          fatG: 18,
        ),
        '— g · 510 kcal · P — g · C 55.5 g · F 18 g',
      );
    });
  });
}
