import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/vietnam_local/models/vietnam_local_models.dart';

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
          },
        ],
      }, fallbackDate: DateTime(2026, 7, 27));

      expect(result.date, DateTime(2026, 7, 28));
      expect(result.hasConfiguration, isTrue);
      expect(result.targetCalories, 1000);
      expect(result.items, hasLength(1));
      expect(result.items.single.name, 'Gà xào rau củ');
      expect(result.items.single.caloriesKcal, 290);
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
