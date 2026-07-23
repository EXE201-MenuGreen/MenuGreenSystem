import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/tracking/repositories/nutrition_tracking_repository.dart';
import 'package:frontend/features/tracking/widgets/search_and_log_modal.dart';

class _FakeNutritionTrackingRepository extends NutritionTrackingRepository {
  String? foodId;
  String? recipeId;
  String? mealType;
  double? quantityG;
  String? notes;
  double? caloriesKcal;
  double? proteinG;
  double? carbsG;
  double? fatG;

  @override
  Future<List<CatalogItem>> getRecipes({String? keyword}) async => [];

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
  }) async {
    this.foodId = foodId;
    this.recipeId = recipeId;
    this.mealType = mealType;
    this.quantityG = quantityG;
    this.notes = notes;
    this.caloriesKcal = caloriesKcal;
    this.proteinG = proteinG;
    this.carbsG = carbsG;
    this.fatG = fatG;
    return true;
  }
}

void main() {
  testWidgets('allows confirming an AI dish when no recipe matches', (
    tester,
  ) async {
    final repository = _FakeNutritionTrackingRepository();
    var succeeded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAndLogModal(
            repository: repository,
            keyword: 'Burger Bò Tự Làm',
            defaultGrams: 225,
            isRecipe: true,
            initialMealType: 'lunch',
            fallbackNutrition: CvNutritionInfo(
              tongCalories: 400,
              proteinG: 30,
              carbsG: 25,
              fatG: 20,
              fiberG: 4,
            ),
            fallbackNutritionMultiplier: 1.5,
            onSuccess: () => succeeded = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận món ăn'), findsNWidgets(2));
    expect(
      find.textContaining('Bạn vẫn có thể lưu bằng chỉ số dinh dưỡng'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận món ăn'));
    await tester.pump();

    expect(succeeded, isTrue);
    expect(repository.foodId, isNull);
    expect(repository.recipeId, isNull);
    expect(repository.mealType, 'lunch');
    expect(repository.quantityG, 225);
    expect(repository.notes, contains('Burger Bò Tự Làm'));
    expect(repository.caloriesKcal, 600);
    expect(repository.proteinG, 45);
    expect(repository.carbsG, 37.5);
    expect(repository.fatG, 30);
  });

  testWidgets('routes Office confirmation through the sync submitter', (
    tester,
  ) async {
    final repository = _FakeNutritionTrackingRepository();
    String? submittedMealType;
    double? submittedQuantity;
    var succeeded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAndLogModal(
            repository: repository,
            keyword: 'Burger Bò Tự Làm',
            defaultGrams: 225,
            isRecipe: true,
            initialMealType: 'lunch',
            fallbackNutrition: CvNutritionInfo(
              tongCalories: 400,
              proteinG: 30,
              carbsG: 25,
              fatG: 20,
              fiberG: 4,
            ),
            syncsOfficePlan: true,
            submitter: (mealType, quantityG, _) async {
              submittedMealType = mealType;
              submittedQuantity = quantityG;
              return true;
            },
            onSuccess: () => succeeded = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận và cập nhật'), findsOneWidget);
    expect(find.textContaining('cập nhật kế hoạch Office'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Xác nhận và cập nhật'),
    );
    await tester.pump();

    expect(succeeded, isTrue);
    expect(submittedMealType, 'lunch');
    expect(submittedQuantity, 225);
    expect(repository.mealType, isNull);
  });
}
