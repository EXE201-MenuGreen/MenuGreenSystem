import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/meal_plan/models/meal_plan_requests.dart';

void main() {
  test('serializes configured meal time as an API TimeOnly value', () {
    final scheduledTime = DateTime(2026, 8, 12, 9, 5);

    expect(
      AddItemRequest(
        mealType: 'breakfast',
        scheduledTime: scheduledTime,
      ).toJson()['scheduledTime'],
      '09:05',
    );
    expect(
      CreateItemRequest(
        mealType: 'breakfast',
        scheduledTime: scheduledTime,
      ).toJson()['scheduledTime'],
      '09:05',
    );
  });
}
