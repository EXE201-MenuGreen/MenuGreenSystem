import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_pt/models/coach_report_models.dart';
import 'package:frontend/features/coach_pt/repositories/coach_meal_plan_repository.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_models.dart';
import 'package:frontend/features/tracking/models/meal_log_item.dart';

void main() {
  test('coach adjustment serializes ingredient portions', () {
    final adjustment = MealPlanAdjustment(
      action: 'replace',
      mealType: 'lunch',
      plannedDate: DateTime(2026, 8, 14),
      recipeId: 'recipe-1',
      targetCalories: 391,
      quantityG: 393,
      ingredients: const [
        MealPlanIngredientPortion(
          ingredientId: 'chicken',
          quantity: 150,
          unit: 'g',
        ),
        MealPlanIngredientPortion(
          ingredientId: 'rice',
          quantity: 130,
          unit: 'g',
        ),
      ],
    );

    final json = adjustment.toJson();
    final ingredients = json['ingredients'] as List<dynamic>;

    expect(json['quantityG'], 393);
    expect(ingredients, hasLength(2));
    expect((ingredients[1] as Map<String, dynamic>)['quantity'], 130);
  });

  test('approved plan parses adjusted ingredient snapshot', () {
    final item = MealPlanItemModel.fromJson({
      'Id': 'item-1',
      'MealType': 'lunch',
      'RecipeId': 'recipe-1',
      'TargetCalories': 391,
      'QuantityG': 393,
      'IsCompleted': false,
      'Ingredients': [
        {
          'IngredientId': 'chicken',
          'Name': 'Ức gà',
          'Quantity': 150,
          'Unit': 'g',
          'CaloriesKcal': 180,
          'ProteinG': 39,
        },
      ],
    });

    expect(item.quantityG, 393);
    expect(item.ingredients.single.ingredientName, 'Ức gà');
    expect(item.ingredients.single.quantity, 150);
    expect(item.ingredients.single.proteinG, 39);
  });

  test('meal log parses the actually consumed ingredient snapshot', () {
    final log = MealLogItem.fromJson({
      'Id': 'log-1',
      'MealType': 'lunch',
      'RecipeId': 'recipe-1',
      'QuantityG': 196.5,
      'CaloriesKcal': 195.5,
      'ConsumptionRatio': 0.5,
      'Ingredients': [
        {
          'IngredientId': 'chicken',
          'Name': 'Ức gà',
          'Quantity': 75,
          'Unit': 'g',
          'CaloriesKcal': 90,
          'ProteinG': 19.5,
        },
      ],
    });

    expect(log.consumptionRatio, 0.5);
    expect(log.quantityG, 196.5);
    expect(log.ingredients.single.quantity, 75);
    expect(log.ingredients.single.caloriesKcal, 90);
  });

  test('direct coach meal plan sends adjusted recipe ingredients', () {
    final item = ClientMealPlanItemPayload(
      mealType: 'breakfast',
      recipeId: 'recipe-1',
      targetCalories: 420,
      quantityG: 335,
      ingredients: const [
        MealPlanIngredientPortion(
          ingredientId: 'beef',
          quantity: 120,
          unit: 'g',
        ),
        MealPlanIngredientPortion(
          ingredientId: 'noodle',
          quantity: 180,
          unit: 'g',
        ),
      ],
    );

    final json = item.toJson();
    final ingredients = json['ingredients'] as List<dynamic>;
    expect(json['quantityG'], 335);
    expect(ingredients, hasLength(2));
    expect((ingredients.first as Map<String, dynamic>)['quantity'], 120);
  });
}
