import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_stats_period.dart';

void main() {
  final today = DateTime(2026, 7, 20, 10, 30);

  test('day period contains only the selected historical date', () {
    final range = mealPlanStatsRangeFor(
      MealPlanStatsPeriod.day,
      DateTime(2026, 7, 18, 23, 45),
      currentDate: today,
    );

    expect(range.from, DateTime(2026, 7, 18));
    expect(range.to, DateTime(2026, 7, 18));
  });

  test('historical week runs from Monday through Sunday', () {
    final range = mealPlanStatsRangeFor(
      MealPlanStatsPeriod.week,
      DateTime(2026, 7, 15),
      currentDate: today,
    );

    expect(range.from, DateTime(2026, 7, 13));
    expect(range.to, DateTime(2026, 7, 19));
  });

  test('current week is capped at today', () {
    final range = mealPlanStatsRangeFor(
      MealPlanStatsPeriod.week,
      today,
      currentDate: today,
    );

    expect(range.from, DateTime(2026, 7, 20));
    expect(range.to, DateTime(2026, 7, 20));
  });

  test('historical month includes the entire month', () {
    final range = mealPlanStatsRangeFor(
      MealPlanStatsPeriod.month,
      DateTime(2026, 6, 10),
      currentDate: today,
    );

    expect(range.from, DateTime(2026, 6));
    expect(range.to, DateTime(2026, 6, 30));
  });

  test('current month is capped at today', () {
    final range = mealPlanStatsRangeFor(
      MealPlanStatsPeriod.month,
      DateTime(2026, 7, 1),
      currentDate: today,
    );

    expect(range.from, DateTime(2026, 7));
    expect(range.to, DateTime(2026, 7, 20));
  });

  test('future selection is defensively clamped to today', () {
    final range = mealPlanStatsRangeFor(
      MealPlanStatsPeriod.day,
      DateTime(2026, 7, 25),
      currentDate: today,
    );

    expect(range.from, DateTime(2026, 7, 20));
    expect(range.to, DateTime(2026, 7, 20));
  });
}
