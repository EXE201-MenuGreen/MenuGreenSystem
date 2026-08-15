import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/gymer/models/route_approval_detail.dart';
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

  test('stale approval item id resolves to the current adjusted portion', () {
    final date = DateTime(2026, 8, 13);
    final snapshot = RouteApprovalMeal(
      id: 'deleted-item-id',
      mealType: 'breakfast',
      name: 'CÆ¡m táº¥m sÆ°á»n bÃ¬ cháº£',
      calories: 530,
      isCompleted: false,
      foodId: 'food-com-tam',
      plannedDate: date,
      scheduledTime: '07:30:00',
      quantityG: 299.3,
    );
    final currentItem = MealPlanItemModel(
      id: 'current-item-id',
      mealType: 'breakfast',
      foodId: 'food-com-tam',
      targetCalories: 530,
      isCompleted: false,
      foodName: 'CÆ¡m táº¥m sÆ°á»n bÃ¬ cháº£',
      plannedDate: date,
      scheduledTime: '07:30:00',
      quantityG: 299.3,
    );
    final plan = UserMealPlan(
      id: 'plan-1',
      title: 'Daily plan',
      planType: 'DAILY',
      startDate: '2026-08-13',
      targetCalories: 2000,
      items: [currentItem],
    );

    expect(resolveCurrentRouteMealItem(snapshot, plan)?.id, 'current-item-id');
  });
}
