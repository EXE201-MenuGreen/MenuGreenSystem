import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/tracking/models/meal_log_item.dart';

void main() {
  group('MealLogItem type classification', () {
    test('recognizes a newly saved AI ingredient scan', () {
      final item = MealLogItem.fromJson({
        'id': 'ingredient-log',
        'mealType': 'lunch',
        'quantityG': 200,
        'caloriesKcal': 286,
        'loggedAt': '2026-08-14T05:33:00Z',
        'displayName': 'Thịt bò tươi',
        'sourceType': 'AiIngredientScan',
      });

      expect(item.isIngredient, isTrue);
    });

    test('recognizes a legacy ingredient scan from its notes', () {
      final item = MealLogItem.fromJson({
        'id': 'legacy-log',
        'mealType': 'lunch',
        'quantityG': 200,
        'caloriesKcal': 286,
        'loggedAt': '2026-08-14T05:33:00Z',
        'displayName': 'Thịt bò tươi',
        'sourceType': 'AiScan',
        'notes': 'Nguyên liệu nhận diện từ AI scan: Thịt bò tươi',
      });

      expect(item.isIngredient, isTrue);
    });

    test('keeps dishes separate from ingredients', () {
      final item = MealLogItem.fromJson({
        'id': 'dish-log',
        'mealType': 'lunch',
        'quantityG': 350,
        'caloriesKcal': 520,
        'loggedAt': '2026-08-14T05:33:00Z',
        'displayName': 'Bò xào rau củ',
        'sourceType': 'AiDishScan',
      });

      expect(item.isIngredient, isFalse);
    });
  });
}
