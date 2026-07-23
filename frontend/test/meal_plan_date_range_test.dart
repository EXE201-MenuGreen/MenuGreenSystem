import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_date_range.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_requests.dart';

void main() {
  group('normalizeMealPlanDateRange', () {
    test('daily plan always ends on its start date', () {
      final range = normalizeMealPlanDateRange(
        planType: PlanType.daily,
        startDate: DateTime(2026, 7, 20, 18, 45),
        endDate: DateTime(2026, 8, 1),
      );

      expect(range.startDate, DateTime(2026, 7, 20));
      expect(range.endDate, DateTime(2026, 7, 20));
    });

    test('weekly plan always spans seven inclusive calendar days', () {
      final range = normalizeMealPlanDateRange(
        planType: PlanType.weekly,
        startDate: DateTime(2026, 7, 29, 9),
        endDate: DateTime(2026, 7, 30),
      );

      expect(range.startDate, DateTime(2026, 7, 29));
      expect(range.endDate, DateTime(2026, 8, 4));
    });

    test('custom plan keeps a valid inclusive date range', () {
      final range = normalizeMealPlanDateRange(
        planType: PlanType.custom,
        startDate: DateTime(2026, 7, 20, 8),
        endDate: DateTime(2026, 7, 31, 23, 59),
      );

      expect(range.startDate, DateTime(2026, 7, 20));
      expect(range.endDate, DateTime(2026, 7, 31));
    });

    test('custom plan accepts the same start and end date', () {
      final range = normalizeMealPlanDateRange(
        planType: PlanType.custom,
        startDate: DateTime(2026, 7, 20),
        endDate: DateTime(2026, 7, 20),
      );

      expect(range.endDate, range.startDate);
    });

    test('custom plan requires an end date', () {
      expect(
        () => normalizeMealPlanDateRange(
          planType: PlanType.custom,
          startDate: DateTime(2026, 7, 20),
        ),
        throwsArgumentError,
      );
    });

    test('custom plan rejects an end date before its start date', () {
      expect(
        () => normalizeMealPlanDateRange(
          planType: PlanType.custom,
          startDate: DateTime(2026, 7, 20),
          endDate: DateTime(2026, 7, 19),
        ),
        throwsArgumentError,
      );
    });
  });
}
