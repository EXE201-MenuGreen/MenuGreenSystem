import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/calorie_adjustment_picker.dart';
import 'package:frontend/core/widgets/daily_calorie_balance_card.dart';
import 'package:frontend/features/vietnam_local/models/vietnam_local_models.dart';
import 'package:frontend/features/vietnam_local/views/gym_goals_screen.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_models.dart';

void main() {
  group('GymPlanSuggestions', () {
    test(
      'an approved route is treated as PT-managed and cannot be recreated',
      () {
        final plan = UserMealPlan(
          id: 'approved-plan',
          title: 'Approved route',
          planType: 'DAILY',
          startDate: '2026-08-13',
          targetCalories: 2000,
          generatedBy: 'PT_APPROVED',
          status: 'Approved',
          items: const [],
        );

        expect(gymPlanIsPtManaged(plan), isTrue);
      },
    );

    test('keeps an unconfigured date empty', () {
      final result = GymPlanSuggestions.fromJson({
        'date': '2026-07-28',
        'hasConfiguration': false,
        'targetCalories': null,
        'items': <dynamic>[],
      }, fallbackDate: DateTime(2026, 7, 27));

      expect(result.date, DateTime(2026, 7, 28));
      expect(result.hasConfiguration, isFalse);
      expect(result.targetCalories, isNull);
      expect(result.items, isEmpty);
    });

    test('reads the scoped calorie target and its daily items', () {
      final result = GymPlanSuggestions.fromJson({
        'Date': '2026-07-28',
        'HasConfiguration': true,
        'TargetCalories': 1000,
        'Items': [
          {
            'Id': 'food-1',
            'Name': 'Gà xào rau củ',
            'Type': 'Food',
            'CaloriesKcal': 290,
            'ProteinG': 26,
            'QuantityG': 180,
          },
        ],
      }, fallbackDate: DateTime(2026, 7, 27));

      expect(result.date, DateTime(2026, 7, 28));
      expect(result.hasConfiguration, isTrue);
      expect(result.targetCalories, 1000);
      expect(result.items, hasLength(1));
      expect(result.items.single.name, 'Gà xào rau củ');
      expect(result.items.single.caloriesKcal, 290);
      expect(result.items.single.quantityG, 180);
    });

    test('initialization payload preserves each suggestion serving size', () {
      const suggestion = LocalRecommendationItem(
        id: 'food-180',
        name: 'Bánh mì ốp la',
        caloriesKcal: 505,
        quantityG: 180,
      );

      final payload = gymSuggestionPlanItem(
        suggestion,
        'breakfast',
        plannedDate: DateTime(2026, 8, 15),
      );

      expect(payload['foodId'], 'food-180');
      expect(payload['recipeId'], isNull);
      expect(payload['quantityG'], 180);
      expect(payload['plannedDate'], '2026-08-15');
      expect(payload['scheduledTime'], '07:30');
    });

    test('auto balance is available only before sending to PT', () {
      expect(
        gymCanAutoBalancePlan(
          hasPlan: true,
          hasMeals: true,
          hasTarget: true,
          hasAcceptedPtConnection: true,
          hasPtProgram: false,
          isSentToPt: false,
          isLoading: false,
        ),
        isTrue,
      );
      expect(
        gymCanAutoBalancePlan(
          hasPlan: true,
          hasMeals: true,
          hasTarget: true,
          hasAcceptedPtConnection: true,
          hasPtProgram: false,
          isSentToPt: true,
          isLoading: false,
        ),
        isFalse,
      );
      expect(
        gymCanAutoBalancePlan(
          hasPlan: true,
          hasMeals: true,
          hasTarget: true,
          hasAcceptedPtConnection: true,
          hasPtProgram: true,
          isSentToPt: false,
          isLoading: false,
        ),
        isFalse,
      );
    });

    test(
      'calculates below, balanced and above totals from the same target',
      () {
        expect(
          calorieAdjustmentTotal(
            targetCalories: 2000,
            mode: CalorieAdjustmentMode.below,
            percentage: 10,
          ),
          1800,
        );
        expect(
          calorieAdjustmentTotal(
            targetCalories: 2000,
            mode: CalorieAdjustmentMode.balanced,
            percentage: 10,
          ),
          2000,
        );
        expect(
          calorieAdjustmentTotal(
            targetCalories: 2000,
            mode: CalorieAdjustmentMode.above,
            percentage: 10,
          ),
          2200,
        );
      },
    );

    testWidgets('an exact Gym plan can still open calorie customization', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyCalorieBalanceCard(
              totalCalories: 2000,
              targetCalories: 2000,
              mealCount: 4,
              actionLabel: 'Tùy chỉnh',
              allowAdjustmentWhenExact: true,
              onAutoBalance: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tùy chỉnh'));

      expect(pressed, isTrue);
    });
  });

  group('GymGoalProfile.resolveForDate', () {
    test('uses day values before week and month values', () {
      final profile = GymGoalProfile(
        dailyDetails: const [
          GymDayDetail(
            dayOfWeek: 'Tuesday',
            dateString: '2026-07-28',
            isTraining: true,
            customCalories: 2000,
            minCalories: 500,
            maxCalories: 2000,
          ),
        ],
        weeklyDetails: const [
          GymWeeklyDetail(
            weekStartDateString: '2026-07-27',
            customCalories: 1700,
            minCalories: 400,
            maxCalories: 1800,
          ),
        ],
        monthlyDetails: const [
          GymMonthlyDetail(monthString: '2026-07', customCalories: 1600),
        ],
      );

      final result = profile.resolveForDate(DateTime(2026, 7, 28));

      expect(result.hasScopedConfiguration, isTrue);
      expect(result.scope, GymConfigurationScope.day);
      expect(result.isTraining, isTrue);
      expect(result.targetCalories, 2000);
      expect(result.minCalories, 500);
      expect(result.maxCalories, 2000);
    });

    test('inherits missing bounds from week then month', () {
      final profile = GymGoalProfile(
        dailyDetails: const [
          GymDayDetail(
            dayOfWeek: 'Tuesday',
            dateString: '2026-07-28',
            isTraining: false,
            customCalories: 1500,
          ),
        ],
        weeklyDetails: const [
          GymWeeklyDetail(weekStartDateString: '2026-07-27', minCalories: 450),
        ],
        monthlyDetails: const [
          GymMonthlyDetail(monthString: '2026-07', maxCalories: 1900),
        ],
      );

      final result = profile.resolveForDate(DateTime(2026, 7, 28));

      expect(result.targetCalories, 1500);
      expect(result.minCalories, 450);
      expect(result.maxCalories, 1900);
    });
  });
}
