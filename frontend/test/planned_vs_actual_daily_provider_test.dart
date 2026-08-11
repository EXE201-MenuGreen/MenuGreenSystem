import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_models.dart';
import 'package:frontend/features/meal_plan/repositories/meal_plan_repository.dart';
import 'package:frontend/features/tracking/repositories/nutrition_tracking_repository.dart';
import 'package:frontend/features/vietnam_local/models/vietnam_local_models.dart';
import 'package:frontend/features/vietnam_local/providers/planned_vs_actual_provider.dart';
import 'package:frontend/features/vietnam_local/repositories/vietnam_local_repositories.dart';
import 'package:frontend/features/vietnam_local/views/planned_vs_actual_screen.dart';
import 'package:provider/provider.dart';

void main() {
  test('daily report requests and exposes only the selected date', () async {
    final analytics = _FakeAnalyticsRepository();
    final mealPlans = _FakeMealPlanRepository();
    final nutrition = _FakeNutritionRepository();
    final provider = PlannedVsActualProvider(
      repository: analytics,
      mealPlanRepository: mealPlans,
      nutritionTrackingRepository: nutrition,
    );
    final selectedDate = DateTime(2026, 8, 9, 18, 30);

    provider.setDate(selectedDate);
    await provider.loadAll();

    expect(provider.from, DateTime(2026, 8, 9));
    expect(provider.to, DateTime(2026, 8, 9));
    expect(analytics.requestedFrom, DateTime(2026, 8, 9));
    expect(analytics.requestedTo, DateTime(2026, 8, 9));
    expect(mealPlans.requestedDate, DateTime(2026, 8, 9));
    expect(nutrition.requestedDate, DateTime(2026, 8, 9));
    expect(provider.dailyPlan?.items.first.displayName, 'Bún bò Huế');
    expect(provider.dailySummary?.mealLogs.first.displayName, 'Bún bò Huế');
    expect(provider.dailySummary?.totalCalories, 1244);
    expect(provider.dailySummary?.mealLogs.first.quantityG, 450);
    expect(provider.dailySummary?.mealLogs.first.caloriesKcal, 510);
    expect(provider.summary?.totalActual.caloriesKcal, 1244);
  });

  testWidgets('daily report renders separate planned and actual meal lists', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = PlannedVsActualProvider(
      repository: _FakeAnalyticsRepository(),
      mealPlanRepository: _FakeMealPlanRepository(),
      nutritionTrackingRepository: _FakeNutritionRepository(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: PlannedVsActualScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Báo cáo dinh dưỡng theo ngày'), findsOneWidget);
    expect(find.text('Tiến độ trong ngày'), findsOneWidget);
    expect(find.text('1244'), findsOneWidget);
    expect(find.text('1244 kcal'), findsWidgets);
    expect(find.text('Món trong kế hoạch'), findsOneWidget);
    // The persisted plan flags intentionally start false in this fixture.
    // Linked actual logs must still make both planned rows show as eaten.
    expect(find.text('Đã ăn'), findsNWidgets(2));
    expect(find.text('Chưa ăn'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Món đã ăn thực tế'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Món đã ăn thực tế'), findsOneWidget);
    expect(find.text('Bún bò Huế'), findsWidgets);
  });
}

class _FakeAnalyticsRepository extends PlannedVsActualRepository {
  DateTime? requestedFrom;
  DateTime? requestedTo;

  @override
  Future<ApiResult<PlannedVsActualSummary>> getSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    requestedFrom = from;
    requestedTo = to;
    return ApiResult(
      success: true,
      data: PlannedVsActualSummary(
        from: from!,
        to: to!,
        totalPlanned: const PlannedNutrition(caloriesKcal: 1244),
        totalActual: const PlannedNutrition(caloriesKcal: 1244),
        details: [
          PlannedVsActualDay(
            date: from,
            planned: const PlannedNutrition(caloriesKcal: 1244),
            actual: const PlannedNutrition(caloriesKcal: 1244),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<AdherenceScore>> getAdherenceScore({
    DateTime? from,
    DateTime? to,
  }) async => const ApiResult(
    success: true,
    data: AdherenceScore(
      overallScore: 100,
      mealCompletionRate: 100,
      calorieDeviationScore: 100,
      macroDeviationScore: 100,
      unplannedPenaltyScore: 100,
      rating: 'EXCELLENT',
      feedback: '',
    ),
  );

  @override
  Future<ApiResult<DriftAnalysis>> getDriftAnalysis({
    DateTime? from,
    DateTime? to,
  }) async => const ApiResult(success: true, data: DriftAnalysis());
}

class _FakeMealPlanRepository extends MealPlanRepository {
  DateTime? requestedDate;

  @override
  Future<UserMealPlan?> getByDate(DateTime date) async {
    requestedDate = date;
    return UserMealPlan(
      id: 'plan-1',
      title: 'Ngày 09/08',
      planType: 'DAILY',
      startDate: '2026-08-09',
      targetCalories: 2000,
      items: [
        MealPlanItemModel(
          id: 'item-1',
          mealType: 'breakfast',
          foodId: 'food-1',
          targetCalories: 510,
          isCompleted: false,
          foodName: 'Bún bò Huế',
        ),
        MealPlanItemModel(
          id: 'item-2',
          mealType: 'lunch',
          recipeId: 'recipe-1',
          targetCalories: 734,
          isCompleted: false,
          recipeName: 'Canh kim chi thịt bò',
        ),
      ],
    );
  }
}

class _FakeNutritionRepository extends NutritionTrackingRepository {
  DateTime? requestedDate;

  @override
  Future<MealDaySummary?> getDailySummary(DateTime date) async {
    requestedDate = date;
    return MealDaySummary(
      date: '2026-08-09',
      totalCalories: 1244,
      totalProteinG: 103,
      totalCarbsG: 95,
      totalFatG: 49,
      targetCalories: 2000,
      targetProteinG: 100,
      targetCarbsG: 200,
      targetFatG: 66,
      mealLogs: [
        MealLogItem(
          id: 'log-1',
          mealType: 'breakfast',
          quantityG: 450,
          caloriesKcal: 510,
          loggedAt: DateTime(2026, 8, 9, 8),
          displayName: 'Bún bò Huế',
          foodId: 'food-1',
          mealPlanItemId: 'item-1',
        ),
        MealLogItem(
          id: 'log-2',
          mealType: 'lunch',
          quantityG: 100,
          caloriesKcal: 734,
          loggedAt: DateTime(2026, 8, 9, 12),
          displayName: 'Canh kim chi thịt bò',
          recipeId: 'recipe-1',
          mealPlanItemId: 'item-2',
        ),
      ],
    );
  }
}
