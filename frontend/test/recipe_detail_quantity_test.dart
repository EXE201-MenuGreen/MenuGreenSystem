import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/discover/models/food_models.dart';
import 'package:frontend/features/discover/repositories/food_discovery_repository.dart';
import 'package:frontend/features/discover/views/recipe_detail_screen.dart';

void main() {
  test('recipe model parses linked food default serving', () {
    final recipe = RecipeItem.fromJson({
      'id': 'recipe-1',
      'title': 'Bánh mì ốp la',
      'defaultServingG': 180,
    });

    expect(recipe.defaultServingG, 180);
  });

  testWidgets('recipe detail prefers the adjusted planned quantity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailScreen(
          recipeId: 'recipe-1',
          plannedQuantityG: 100,
          repository: _FakeFoodDiscoveryRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khối lượng món: 100 g'), findsOneWidget);
    expect(find.text('Khối lượng món: 180 g'), findsNothing);
  });

  testWidgets('recipe detail falls back to linked food default serving', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecipeDetailScreen(
          recipeId: 'recipe-1',
          repository: _FakeFoodDiscoveryRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khối lượng món: 180 g'), findsOneWidget);
  });
}

class _FakeFoodDiscoveryRepository extends FoodDiscoveryRepository {
  @override
  Future<RecipeItem?> getRecipeById(
    String id, {
    String allergyMode = 'warn',
  }) async {
    return RecipeItem(
      id: id,
      title: 'Bánh mì ốp la',
      foodId: 'food-1',
      servings: 1,
    );
  }

  @override
  Future<FoodItem?> getFoodById(
    String id, {
    String allergyMode = 'warn',
  }) async {
    return FoodItem(id: id, nameVi: 'Bánh mì ốp la', defaultServingG: 180);
  }

  @override
  Future<Map<String, double>> getRecipeNutrition(String id) async {
    return const {
      'caloriesKcal': 420,
      'proteinG': 18,
      'carbsG': 45,
      'fatG': 18,
    };
  }
}
