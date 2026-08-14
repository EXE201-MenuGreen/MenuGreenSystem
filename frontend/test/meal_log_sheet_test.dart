import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/tracking/repositories/nutrition_tracking_repository.dart';
import 'package:frontend/features/tracking/widgets/meal_log_sheet.dart';

class _FakeNutritionTrackingRepository extends NutritionTrackingRepository {
  int getFoodsCalls = 0;
  String? customName;
  String? mealType;
  double? quantityG;

  @override
  Future<List<CatalogItem>> getFoods({String? keyword}) async {
    getFoodsCalls++;
    return const [];
  }

  @override
  Future<bool> createMealLog({
    String? foodId,
    String? recipeId,
    required String mealType,
    required double quantityG,
    String? notes,
    DateTime? loggedAt,
    double? caloriesKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? customName,
    String? sourceType,
  }) async {
    this.customName = customName;
    this.mealType = mealType;
    this.quantityG = quantityG;
    return true;
  }
}

void main() {
  testWidgets('logs a suggested custom dish without rebuilding catalog loads', (
    tester,
  ) async {
    final repository = _FakeNutritionTrackingRepository();
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showMealLogSheet(
                  context,
                  initialFoodName: 'Súp nấm hạt sen gà xé',
                  caloriesKcal: 250,
                  repository: repository,
                );
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.text('Ghi vào nhật ký'), findsOneWidget);
    expect(find.text('Món: Súp nấm hạt sen gà xé'), findsOneWidget);
    expect(find.text('Tải danh sách'), findsNothing);
    expect(repository.getFoodsCalls, 0);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Ghi'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, isTrue);
    expect(repository.customName, 'Súp nấm hạt sen gà xé');
    expect(repository.mealType, 'breakfast');
    expect(repository.quantityG, 100);
  });
}
