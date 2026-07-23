enum MealPlanStatsPeriod { day, week, month }

/// Returns the calendar period containing [selectedDate].
///
/// Completed periods include their full week or month. The current period is
/// capped at [currentDate] so statistics never include future dates.
({DateTime from, DateTime to}) mealPlanStatsRangeFor(
  MealPlanStatsPeriod period,
  DateTime selectedDate, {
  required DateTime currentDate,
}) {
  final today = _dateOnly(currentDate);
  final requestedDate = _dateOnly(selectedDate);
  final anchor = requestedDate.isAfter(today) ? today : requestedDate;

  final range = switch (period) {
    MealPlanStatsPeriod.day => (from: anchor, to: anchor),
    MealPlanStatsPeriod.week => (
      from: anchor.subtract(Duration(days: anchor.weekday - DateTime.monday)),
      to: anchor
          .subtract(Duration(days: anchor.weekday - DateTime.monday))
          .add(const Duration(days: 6)),
    ),
    MealPlanStatsPeriod.month => (
      from: DateTime(anchor.year, anchor.month),
      to: DateTime(anchor.year, anchor.month + 1, 0),
    ),
  };

  return (from: range.from, to: range.to.isAfter(today) ? today : range.to);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
