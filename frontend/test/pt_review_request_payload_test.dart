import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/advanced/repositories/advanced_repository.dart';

void main() {
  test('RouteApproval carries the exact meal plan id to PT', () {
    final payload = buildPtReviewReportPayload(
      '2026-08-13',
      7,
      requestType: 'RouteApproval',
      mealPlanId: 'plan-1889',
      submittedTotalCalories: 1889,
    );

    expect(payload['weekStartDate'], '2026-08-13');
    expect(payload['requestType'], 'RouteApproval');
    expect(payload['mealPlanId'], 'plan-1889');
    expect(payload['submittedTotalCalories'], 1889);
  });

  test('weekly reports remain backward compatible without a meal plan id', () {
    final payload = buildPtReviewReportPayload('2026-08-10', 7);

    expect(payload['requestType'], 'WeeklyReport');
    expect(payload.containsKey('mealPlanId'), isFalse);
    expect(payload.containsKey('submittedTotalCalories'), isFalse);
  });
}
