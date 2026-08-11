import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/meal_schedule_format.dart';

void main() {
  test('returns the expected default time for each meal', () {
    expect(defaultMealScheduledTime('breakfast'), '07:30');
    expect(defaultMealScheduledTime('lunch'), '12:00');
    expect(defaultMealScheduledTime('dinner'), '18:30');
    expect(defaultMealScheduledTime('snack'), '15:00');
  });

  test('normalizes API TimeOnly values and falls back for legacy data', () {
    expect(mealScheduledTimeLabel('07:30:00', mealType: 'breakfast'), '07:30');
    expect(mealScheduledTimeLabel(null, mealType: 'dinner'), '18:30');
  });

  test('formats planned dates in Vietnamese display order', () {
    expect(mealPlannedDateLabel(DateTime(2026, 8, 12)), '12/08/2026');
  });
}
