import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_responses.dart';

void main() {
  group('MealPlanStreak', () {
    test('maps the current backend field names and normalizes percentage', () {
      final streak = MealPlanStreak.fromJson({
        'currentStreakDays': 3,
        'bestStreakDays': 7,
        'lastTrackedDate': '2026-07-20',
        'totalTrackedDays': 12,
        'weeklyAdherenceRate': 75,
      });

      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 7);
      expect(streak.lastCompletedDate, DateTime(2026, 7, 20));
      expect(streak.totalCompletedDays, 12);
      expect(streak.averageAdherence, 0.75);
    });

    test('keeps compatibility with the legacy response fields', () {
      final streak = MealPlanStreak.fromJson({
        'currentStreak': 2,
        'longestStreak': 4,
        'totalCompletedDays': 6,
        'averageAdherence': 0.5,
      });

      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 4);
      expect(streak.totalCompletedDays, 6);
      expect(streak.averageAdherence, 0.5);
    });
  });

  test('MealPlanCompare maps macro totals and weekly data', () {
    final compare = MealPlanCompare.fromJson({
      'from': '2026-07-01',
      'to': '2026-07-20',
      'plannedCalories': 2000,
      'actualCalories': 1600,
      'caloriePercent': 0.8,
      'plannedProtein': 120,
      'actualProtein': 90,
      'proteinPercent': 0.75,
      'plannedCarbs': 250,
      'actualCarbs': 200,
      'carbsPercent': 0.8,
      'plannedFat': 60,
      'actualFat': 50,
      'fatPercent': 0.8333,
      'completedDays': 2,
      'totalDays': 3,
      'weeklyData': [
        {
          'weekNumber': 1,
          'plannedCalories': 2000,
          'actualCalories': 1600,
          'percent': 0.8,
        },
      ],
    });

    expect(compare.plannedProtein, 120);
    expect(compare.actualCarbs, 200);
    expect(compare.completedDays, 2);
    expect(compare.totalDays, 3);
    expect(compare.weeklyData, hasLength(1));
    expect(compare.weeklyData.single.percent, 0.8);
  });

  test('dashboard maps backend totals and normalizes completion rate', () {
    final dashboard = MealPlanDayDashboard.fromJson({
      'date': '2026-07-20',
      'totalPlannedCalories': 950,
      'totalActualCalories': 450,
      'plannedProtein': 72,
      'actualProtein': 26,
      'plannedCarbs': 104,
      'actualCarbs': 37,
      'plannedFat': 38,
      'actualFat': 13,
      'plannedItemsCount': 2,
      'completedItemsCount': 1,
      'completionRate': 50,
      'items': [
        {
          'id': 'breakfast',
          'mealType': 'breakfast',
          'targetCalories': 450,
          'proteinG': 30,
          'carbsG': 40,
          'fatG': 15,
          'isCompleted': true,
        },
        {
          'id': 'lunch',
          'mealType': 'lunch',
          'targetCalories': 500,
          'proteinG': 35,
          'carbsG': 55,
          'fatG': 18,
          'isCompleted': false,
        },
      ],
    });

    expect(dashboard.plannedCalories, 950);
    expect(dashboard.actualCalories, 450);
    expect(dashboard.plannedProtein, 72);
    expect(dashboard.actualProtein, 26);
    expect(dashboard.plannedCarbs, 104);
    expect(dashboard.actualCarbs, 37);
    expect(dashboard.plannedFat, 38);
    expect(dashboard.actualFat, 13);
    expect(dashboard.completedMeals, 1);
    expect(dashboard.totalMeals, 2);
    expect(dashboard.adherencePercent, 0.5);
    expect(dashboard.plannedItems, hasLength(2));
    expect(dashboard.completedItems.single.id, 'breakfast');
  });

  test('plan list derives progress counts from API items', () {
    final plan = MealPlanListItem.fromJson({
      'id': 'weekly-plan',
      'title': 'Kế hoạch dinh dưỡng tuần mới',
      'planType': 'weekly',
      'isActive': true,
      'items': [
        {'id': '1', 'isCompleted': true},
        {'id': '2', 'status': 'done'},
        {'id': '3', 'isCompleted': false},
      ],
    });

    expect(plan.completedItems, 2);
    expect(plan.totalItems, 3);
  });

  test('convert result accepts the MealLog response returned by the API', () {
    final result = ConvertToLogResult.fromJson({
      'id': 'meal-log-1',
      'caloriesKcal': 420,
    });

    expect(result.success, isTrue);
    expect(result.mealLogId, 'meal-log-1');
  });
}
