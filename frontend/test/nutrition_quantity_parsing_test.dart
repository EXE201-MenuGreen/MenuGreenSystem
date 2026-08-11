import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_pt/models/coach_meal_plan_models.dart';
import 'package:frontend/features/gymer/models/route_approval_detail.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_models.dart';
import 'package:frontend/features/tracking/models/meal_log_item.dart';

void main() {
  test('meal plan item keeps quantity and all macros from camelCase JSON', () {
    final item = MealPlanItemModel.fromJson({
      'id': 'meal-1',
      'mealType': 'lunch',
      'targetCalories': 510,
      'quantityG': 180.5,
      'proteinG': 25,
      'carbsG': 55,
      'fatG': 18,
    });

    expect(item.quantityG, 180.5);
    expect(item.proteinG, 25);
    expect(item.carbsG, 55);
    expect(item.fatG, 18);
  });

  test('route and coach items accept PascalCase QuantityG', () {
    final json = <String, dynamic>{
      'Id': 'meal-2',
      'MealType': 'dinner',
      'Name': 'Tôm rang thịt',
      'TargetCalories': 672,
      'QuantityG': 220,
      'ProteinG': 109,
      'CarbsG': 0,
      'FatG': 24,
    };

    expect(RouteApprovalMeal.fromJson(json).quantityG, 220);
    expect(CoachMealPlanItem.fromJson(json).quantityG, 220);
  });

  test('meal log keeps serving and all actual macros', () {
    final item = MealLogItem.fromJson({
      'Id': 'log-1',
      'MealType': 'breakfast',
      'QuantityG': 150,
      'CaloriesKcal': 576,
      'ProteinG': 28,
      'CarbsG': 27,
      'FatG': 8,
      'DisplayName': 'Hủ tiếu Nam Vang',
    });

    expect(item.quantityG, 150);
    expect(item.caloriesKcal, 576);
    expect(item.proteinG, 28);
    expect(item.carbsG, 27);
    expect(item.fatG, 8);
  });
}
