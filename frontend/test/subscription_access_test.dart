import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/subscription/models/subscription_models.dart';
import 'package:frontend/features/subscription/utils/subscription_access.dart';

void main() {
  UserSubscription subscription({
    required String id,
    required String name,
    required String featureGroup,
    String status = 'Active',
  }) {
    return UserSubscription(
      id: id,
      userId: 'user-1',
      subscriptionPlanId: 'plan-$id',
      subscriptionPlanName: name,
      featureGroup: featureGroup,
      status: status,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      daysRemaining: 30,
    );
  }

  test('multiple plans show Gymer dashboard when any active plan is gym', () {
    final plans = [
      subscription(id: 'office', name: 'Gói Office', featureGroup: 'office'),
      subscription(id: 'gym', name: 'Gói Gym/PT', featureGroup: 'gym'),
    ];

    expect(hasGymerSubscriptionAccess(plans), isTrue);
  });

  test('dashboard stays hidden without an active gym or pro plan', () {
    final plans = [
      subscription(id: 'office', name: 'Gói Office', featureGroup: 'office'),
      subscription(
        id: 'gym',
        name: 'Gói Gym/PT',
        featureGroup: 'gym',
        status: 'Cancelled',
      ),
    ];

    expect(hasGymerSubscriptionAccess(plans), isFalse);
  });
}
