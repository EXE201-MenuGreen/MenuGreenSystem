import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/vietnam_local/models/vietnam_local_models.dart';
import 'package:frontend/features/vietnam_local/views/gym_goals_screen.dart';

void main() {
  group('GymPlanSuggestions', () {
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
