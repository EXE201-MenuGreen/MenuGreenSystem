bool canCreateWeeklyReportOn(DateTime localDateTime) =>
    localDateTime.weekday == DateTime.sunday;

DateTime weeklyReportWeekStart(DateTime localDateTime) {
  final localDate = DateTime(
    localDateTime.year,
    localDateTime.month,
    localDateTime.day,
  );
  return localDate.subtract(Duration(days: localDate.weekday - 1));
}
