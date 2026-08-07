import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/advanced/utils/weekly_report_rules.dart';

void main() {
  test('weekly report can only be created on Sunday in production rule', () {
    expect(
      canCreateWeeklyReportOn(DateTime(2026, 8, 2, 10), allowAnyDay: false),
      isTrue,
    );
    expect(
      canCreateWeeklyReportOn(DateTime(2026, 8, 1, 23, 59), allowAnyDay: false),
      isFalse,
    );
    expect(
      canCreateWeeklyReportOn(DateTime(2026, 8, 3, 0, 1), allowAnyDay: false),
      isFalse,
    );
  });

  test('weekly report can be created on any day in debug/test override', () {
    expect(
      canCreateWeeklyReportOn(DateTime(2026, 8, 1, 10), allowAnyDay: true),
      isTrue,
    );
    expect(
      canCreateWeeklyReportOn(DateTime(2026, 8, 3, 10), allowAnyDay: true),
      isTrue,
    );
  });

  test('mid-week check-in can only be created on Thursday', () {
    expect(
      canCreateMidWeekCheckInOn(DateTime(2026, 8, 6, 10), allowAnyDay: false),
      isTrue,
    );
    expect(
      canCreateMidWeekCheckInOn(
        DateTime(2026, 8, 5, 23, 59),
        allowAnyDay: false,
      ),
      isFalse,
    );
    expect(
      canCreateMidWeekCheckInOn(DateTime(2026, 8, 7, 0, 1), allowAnyDay: false),
      isFalse,
    );
  });

  test('weekly report uses Monday of the current week', () {
    final weekStart = weeklyReportWeekStart(DateTime(2026, 8, 2, 20));
    expect(weekStart, DateTime(2026, 7, 27));
  });
}
