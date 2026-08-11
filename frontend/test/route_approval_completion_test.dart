import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/gymer/views/route_approval_detail_screen.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_models.dart';
import 'package:frontend/features/tracking/models/nutrition_models.dart';

void main() {
  test('linked actual meal keeps route checkbox selected after reload', () {
    final plannedMeal = MealPlanItemModel(
      id: 'plan-item-1',
      mealType: 'breakfast',
      foodId: 'food-1',
      targetCalories: 510,
      isCompleted: false,
      foodName: 'Bún bò Huế',
    );
    final actualMeals = [
      MealLogItem(
        id: 'log-1',
        mealType: 'breakfast',
        quantityG: 450,
        caloriesKcal: 510,
        loggedAt: DateTime(2026, 8, 9, 7, 5),
        displayName: 'Bún bò Huế',
        foodId: 'food-1',
        mealPlanItemId: 'plan-item-1',
      ),
    ];

    expect(isRouteMealCompleted(plannedMeal, actualMeals), isTrue);
  });

  test('unlinked actual meal does not complete another planned item', () {
    final plannedMeal = MealPlanItemModel(
      id: 'plan-item-2',
      mealType: 'lunch',
      recipeId: 'recipe-1',
      targetCalories: 734,
      isCompleted: false,
      recipeName: 'Canh kim chi thịt bò',
    );
    final unrelatedLog = MealLogItem(
      id: 'log-2',
      mealType: 'lunch',
      quantityG: 100,
      caloriesKcal: 734,
      loggedAt: DateTime(2026, 8, 9, 12),
      displayName: 'Canh kim chi thịt bò',
      recipeId: 'recipe-1',
      mealPlanItemId: 'another-plan-item',
    );

    expect(isRouteMealCompleted(plannedMeal, [unrelatedLog]), isFalse);
  });
}
