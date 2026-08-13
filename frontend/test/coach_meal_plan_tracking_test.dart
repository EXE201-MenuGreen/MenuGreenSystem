import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_pt/models/coach_meal_plan_models.dart';
import 'package:frontend/features/coach_pt/providers/coach_meal_plan_provider.dart';
import 'package:frontend/features/coach_pt/repositories/coach_meal_plan_repository.dart';
import 'package:frontend/features/coach_pt/views/coach_meal_plan_detail_screen.dart';
import 'package:provider/provider.dart';

void main() {
  test('nutrition summary reads target fields and actual meal logs', () {
    final summary = ClientDayNutrition.fromJson({
      'Date': '2026-08-11',
      'TargetCalories': 2000,
      'ActualCalories': 1086,
      'TargetProtein': 88,
      'ActualProtein': 43,
      'TargetCarbs': 180,
      'ActualCarbs': 113,
      'TargetFat': 71,
      'ActualFat': 32,
      'Logs': [
        {
          'Id': 'log-1',
          'MealPlanItemId': 'item-1',
          'RecipeTitle': 'Cơm gà',
          'MealType': 'Lunch',
          'CaloriesKcal': 1086,
          'ProteinG': 43,
          'CarbsG': 113,
          'FatG': 32,
          'LoggedAt': '2026-08-11T05:00:00Z',
        },
      ],
    });

    expect(summary.plannedCalories, 2000);
    expect(summary.actualCalories, 1086);
    expect(summary.plannedProtein, 88);
    expect(summary.logs.single.displayName, 'Cơm gà');
    expect(summary.logs.single.isLinkedToPlan, isTrue);
  });

  testWidgets(
    'tracking uses approved item snapshots instead of the configured goal',
    (tester) async {
      final provider = _TrackingProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CoachMealPlanProvider>.value(
            value: provider,
            child: const CoachMealPlanDetailScreen(planId: 'plan-1'),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Theo dõi'));
      await tester.pumpAndSettle();

      expect(find.text('Mục tiêu: 1889 kcal'), findsOneWidget);
      expect(find.text('Đã nạp: 1086 kcal'), findsOneWidget);
      expect(find.text('Mục tiêu: 2000 kcal'), findsNothing);
    },
  );
}

class _TrackingProvider extends CoachMealPlanProvider {
  _TrackingProvider()
    : _plan = CoachMealPlanDetail(
        header: CoachMealPlanHeader(
          id: 'plan-1',
          title: 'Kế hoạch dinh dưỡng 11-08-2026',
          planType: 'daily',
          isActive: true,
          startDate: DateTime(2026, 8, 11),
          endDate: DateTime(2026, 8, 11),
          targetCalories: 2000,
          status: 'Approved',
        ),
        targetProteinG: 88,
        targetCarbsG: 180,
        targetFatG: 71,
        itemsByMeal: {
          'breakfast': [
            CoachMealPlanItem(
              id: 'item-1',
              mealType: 'breakfast',
              displayName: 'Cơm gà',
              targetCalories: 505,
              proteinG: 50,
              carbsG: 100,
              fatG: 30,
            ),
          ],
          'lunch': [
            CoachMealPlanItem(
              id: 'item-2',
              mealType: 'lunch',
              displayName: 'Cá hồi',
              targetCalories: 414,
              proteinG: 38,
              carbsG: 80,
              fatG: 41,
            ),
          ],
          'dinner': [
            CoachMealPlanItem(
              id: 'item-3',
              mealType: 'dinner',
              displayName: 'Vịt quay',
              targetCalories: 550,
            ),
          ],
          'snack': [
            CoachMealPlanItem(
              id: 'item-4',
              mealType: 'snack',
              displayName: 'Trứng sốt cà chua',
              targetCalories: 420,
            ),
          ],
        },
      ),
      _summary = [
        ClientDayNutrition(
          date: DateTime(2026, 8, 11),
          plannedCalories: 2000,
          actualCalories: 1086,
          plannedProtein: 88,
          actualProtein: 43,
          plannedCarbs: 180,
          actualCarbs: 113,
          plannedFat: 71,
          actualFat: 32,
          logs: [
            ClientMealLogItem(
              id: 'log-1',
              mealPlanItemId: 'item-1',
              recipeName: 'Cơm gà',
              mealType: 'breakfast',
              calories: 1086,
              proteinG: 43,
              carbsG: 113,
              fatG: 32,
              loggedAt: DateTime.utc(2026, 8, 11, 5),
            ),
          ],
        ),
      ];

  final CoachMealPlanDetail _plan;
  final List<ClientDayNutrition> _summary;

  @override
  CoachMealPlanDetail? get selectedPlan => _plan;

  @override
  bool get isLoadingDetail => false;

  @override
  String? get detailError => null;

  @override
  List<ClientDayNutrition> get nutritionSummary => _summary;

  @override
  bool get isLoadingNutrition => false;

  @override
  String? get nutritionError => null;

  @override
  Future<void> loadPlanDetail(String planId) async {}

  @override
  Future<void> loadNutritionSummary({
    int days = 7,
    DateTime? from,
    DateTime? to,
  }) async {}
}
