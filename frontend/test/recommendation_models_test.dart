import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/discover/models/food_models.dart';

void main() {
  test('RecommendationGenerateResponse parses the AI worker payload completely', () {
    final response = RecommendationGenerateResponse.fromJson({
      'request_id': 'request-1',
      'created_at': '2026-07-12T08:00:00Z',
      'meal_slot': 'lunch',
      'target_calories': 650,
      'total_calories': 620,
      'total_estimated_cost': 45000,
      'items': [
        {
          'id': 'recipe-1',
          'name': 'Cơm gà rau củ',
          'is_food': false,
          'calories_kcal': 620,
          'protein_g': 35.5,
          'carbs_g': 68,
          'fat_g': 18,
          'fiber_g': 9,
          'estimated_price_vnd': 45000,
          'prep_time_min': 10,
          'cooking_time_min': 20,
          'total_time_min': 30,
          'servings': 2,
          'difficulty': 'easy',
          'description': 'Bữa trưa nhanh, đủ chất.',
          'instructions': ['Sơ chế nguyên liệu', 'Nấu và trình bày'],
          'match_reason': 'Phù hợp mục tiêu calories.',
          'score': 92,
          'matched_allergens': ['Đậu nành'],
          'is_safe_for_user': false,
        },
      ],
    });

    final item = response.items.single;
    expect(response.id, 'request-1');
    expect(response.mealType, 'lunch');
    expect(response.totalCalories, 620);
    expect(response.totalEstimatedCost, 45000);
    expect(item.isFood, isFalse);
    expect(item.carbsG, 68);
    expect(item.fatG, 18);
    expect(item.fiberG, 9);
    expect(item.displayTimeMin, 30);
    expect(item.instructions, 'Sơ chế nguyên liệu\nNấu và trình bày');
    expect(item.score, 0.92);
    expect(item.hasAllergyWarning, isTrue);
  });

  test('History and detail parse JSON persisted by the backend', () {
    const payload = '''
      {
        "meal_slot": "dinner",
        "target_calories": 700,
        "items": [
          {
            "id": "food-1",
            "name": "Cá hấp",
            "is_food": true,
            "calories_kcal": 410,
            "protein_g": 42,
            "carbs_g": 20,
            "fat_g": 12,
            "estimated_price_vnd": 55000,
            "cooking_time_min": 25
          }
        ]
      }
    ''';

    final history = RecommendationHistoryItem.fromJson({
      'id': 'history-1',
      'type': 'AIWorker:generate',
      'summary': payload,
      'confidence': 0.85,
      'createdAt': '2026-07-12T10:00:00Z',
    });
    final detail = RecommendationDetail.fromJson({
      'id': 'history-1',
      'type': 'AIWorker:generate',
      'input': '{"meal_slot":"dinner","target_calories":700}',
      'output': payload,
      'confidence': 0.85,
      'createdAt': '2026-07-12T10:00:00Z',
    });

    expect(history.mealType, 'dinner');
    expect(history.targetCalories, 700);
    expect(history.itemCount, 1);
    expect(detail.mealType, 'dinner');
    expect(detail.targetCalories, 700);
    expect(detail.confidence, 0.85);
    expect(detail.items.single.name, 'Cá hấp');
    expect(detail.items.single.estimatedPriceVnd, 55000);
  });

  test('RecommendationScore converts backend percentage scores to fractions', () {
    final score = RecommendationScore.fromJson({
      'CaloriesScore': 90,
      'MacroScore': 75,
      'AllergyScore': 100,
      'BudgetScore': 60,
      'OverallScore': 81.25,
    });

    expect(score.calorieScore, 0.9);
    expect(score.macroScore, 0.75);
    expect(score.allergyScore, 1);
    expect(score.budgetScore, 0.6);
    expect(score.overallScore, 0.8125);
  });

  test('Food and recipe detail models retain all catalog fields returned by the API', () {
    final food = FoodItem.fromJson({
      'id': 'food-1',
      'nameVi': 'Ức gà',
      'caloriesKcal': 165,
      'proteinG': 31,
      'carbsG': 0,
      'fatG': 3.6,
      'fiberG': 0,
      'estimatedPriceVnd': 35000,
      'defaultServingG': 150,
      'imageUrl': 'https://cdn.example.com/chicken.jpg',
      'region': 'Miền Nam',
      'isActive': true,
    });
    final recipe = RecipeItem.fromJson({
      'id': 'recipe-1',
      'foodId': 'food-1',
      'title': 'Ức gà áp chảo',
      'prepTimeMin': 10,
      'cookTimeMin': 15,
      'totalTimeMin': 25,
      'servings': 2,
      'difficulty': 'easy',
      'mealType': 'dinner',
      'estimatedPriceVnd': 70000,
      'instructions': 'Áp chảo gà đến khi chín.',
      'imageUrl': 'https://cdn.example.com/recipe.jpg',
      'videoUrl': 'https://video.example.com/recipe',
      'isActive': true,
      'ingredients': [],
    });

    expect(food.carbsG, 0);
    expect(food.defaultServingG, 150);
    expect(food.estimatedPriceVnd, 35000);
    expect(food.region, 'Miền Nam');
    expect(recipe.foodId, 'food-1');
    expect(recipe.totalTimeMin, 25);
    expect(recipe.servings, 2);
    expect(recipe.instructions, 'Áp chảo gà đến khi chín.');
    expect(recipe.videoUrl, 'https://video.example.com/recipe');
  });
}
