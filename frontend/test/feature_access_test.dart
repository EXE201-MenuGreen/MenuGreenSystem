import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/subscription/models/subscription_models.dart';

void main() {
  test('free access is the safe fallback', () {
    expect(FeatureAccess.free.tier, 'free');
    expect(FeatureAccess.free.entitlements, contains('free_features'));
    expect(FeatureAccess.free.hasCasual, isFalse);
    expect(FeatureAccess.free.hasOffice, isFalse);
    expect(FeatureAccess.free.hasGym, isFalse);
    expect(FeatureAccess.free.hasAi, isFalse);
  });

  test('entitlement response merges free with paid capabilities', () {
    final access = FeatureAccess.fromJson({
      'tier': 'multi',
      'entitlements': ['office_features', 'gym_features', 'coach_access'],
      'featureGroups': ['office', 'gym'],
      'expiresAt': '2026-08-22T08:00:00Z',
    });

    expect(access.entitlements, contains('free_features'));
    expect(access.hasOffice, isTrue);
    expect(access.hasGym, isTrue);
    expect(access.hasCoachAccess, isTrue);
    expect(access.hasCasual, isFalse);
  });
}
