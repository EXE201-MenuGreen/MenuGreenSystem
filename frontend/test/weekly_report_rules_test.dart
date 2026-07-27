import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/advanced/utils/weekly_report_rules.dart';

void main() {
  test('weekly report can only be created on Sunday', () {
    expect(canCreateWeeklyReportOn(DateTime(2026, 8, 2, 10)), isTrue);
    expect(canCreateWeeklyReportOn(DateTime(2026, 8, 1, 23, 59)), isFalse);
    expect(canCreateWeeklyReportOn(DateTime(2026, 8, 3, 0, 1)), isFalse);
  });

  test('weekly report uses Monday of the current week', () {
    final weekStart = weeklyReportWeekStart(DateTime(2026, 8, 2, 20));
    expect(weekStart, DateTime(2026, 7, 27));
  });
}
