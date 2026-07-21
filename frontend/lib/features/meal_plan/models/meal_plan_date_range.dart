import 'meal_plan_requests.dart';

/// A normalized, inclusive meal-plan date range.
typedef MealPlanDateRange = ({DateTime startDate, DateTime endDate});

/// Normalizes and validates the date range required by [planType].
///
/// Time components are discarded because the meal-plan API stores calendar
/// dates. Daily and weekly plans derive their end date from [startDate], while
/// custom plans require an explicit [endDate] on or after [startDate].
MealPlanDateRange normalizeMealPlanDateRange({
  required PlanType planType,
  required DateTime startDate,
  DateTime? endDate,
}) {
  final normalizedStart = _dateOnly(startDate);

  switch (planType) {
    case PlanType.daily:
      return (startDate: normalizedStart, endDate: normalizedStart);
    case PlanType.weekly:
      return (
        startDate: normalizedStart,
        endDate: DateTime(
          normalizedStart.year,
          normalizedStart.month,
          normalizedStart.day + 6,
        ),
      );
    case PlanType.custom:
      if (endDate == null) {
        throw ArgumentError.notNull('endDate');
      }

      final normalizedEnd = _dateOnly(endDate);
      if (normalizedEnd.isBefore(normalizedStart)) {
        throw ArgumentError.value(
          endDate,
          'endDate',
          'Custom plan end date must be on or after the start date.',
        );
      }

      return (startDate: normalizedStart, endDate: normalizedEnd);
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
