import 'package:flutter/foundation.dart';

bool canCreateWeeklyReportOn(DateTime localDateTime, {bool? allowAnyDay}) {
  final override = allowAnyDay ?? kDebugMode;
  return override || localDateTime.weekday == DateTime.sunday;
}

bool canCreateMidWeekCheckInOn(DateTime localDateTime, {bool? allowAnyDay}) {
  final override = allowAnyDay ?? kDebugMode;
  return override || localDateTime.weekday == DateTime.thursday;
}

DateTime weeklyReportWeekStart(DateTime localDateTime) {
  final localDate = DateTime(
    localDateTime.year,
    localDateTime.month,
    localDateTime.day,
  );
  return localDate.subtract(Duration(days: localDate.weekday - 1));
}
