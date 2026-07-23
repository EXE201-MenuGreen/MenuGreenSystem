import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/subscription/models/subscription_models.dart';
import 'package:frontend/features/subscription/repositories/user_subscription_repository.dart';
import 'package:frontend/features/subscription/views/upgrade_plan_screen.dart';

void main() {
  const basicPlan = SubscriptionPlan(
    id: 'basic-plan',
    name: 'Cơ bản',
    description: 'Công cụ dinh dưỡng cơ bản',
    durationDays: 0,
    priceVnd: 0,
    featureGroup: 'basic',
    isActive: true,
    tierLabel: 'Free',
  );

  test(
    'Basic plan and legacy Basic subscription are recognized as baseline Free',
    () {
      final legacySubscription = UserSubscription(
        id: 'legacy-basic',
        userId: 'user',
        subscriptionPlanId: basicPlan.id,
        subscriptionPlanName: basicPlan.name,
        featureGroup: basicPlan.featureGroup,
        status: 'Active',
        startDate: DateTime.utc(2026, 6, 28),
        endDate: DateTime.utc(2126, 6, 28),
        daysRemaining: 36500,
      );

      expect(basicPlan.isBaselineFree, isTrue);
      expect(legacySubscription.isBaselineFree, isTrue);
    },
  );

  testWidgets('new user sees Basic active by default without an expiry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UpgradePlanScreen(
          repository: _FakeSubscriptionRepository(
            plans: const [basicPlan],
            current: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cơ bản'), findsOneWidget);
    expect(find.text('Trạng thái: Active • Không giới hạn'), findsOneWidget);
    expect(find.text('Đăng ký miễn phí'), findsNothing);
    expect(find.text('Gia hạn gói hiện tại'), findsNothing);
    expect(find.text('Hủy gói'), findsNothing);
  });

  testWidgets('legacy 100-year Basic record never exposes its fake expiry', (
    tester,
  ) async {
    final legacySubscription = UserSubscription(
      id: 'legacy-basic',
      userId: 'user',
      subscriptionPlanId: basicPlan.id,
      subscriptionPlanName: basicPlan.name,
      featureGroup: basicPlan.featureGroup,
      status: 'Active',
      startDate: DateTime.utc(2026, 6, 28),
      endDate: DateTime.utc(2126, 6, 28),
      daysRemaining: 36500,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UpgradePlanScreen(
          repository: _FakeSubscriptionRepository(
            plans: const [basicPlan],
            current: legacySubscription,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trạng thái: Active • Không giới hạn'), findsOneWidget);
    expect(find.textContaining('36500'), findsNothing);
    expect(find.textContaining('2126'), findsNothing);
    expect(find.text('Đăng ký miễn phí'), findsNothing);
  });
}

class _FakeSubscriptionRepository extends UserSubscriptionRepository {
  _FakeSubscriptionRepository({required this.plans, required this.current});

  final List<SubscriptionPlan> plans;
  final UserSubscription? current;

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async => plans;

  @override
  Future<UserSubscription?> getCurrent() async => current;

  @override
  Future<List<SubscriptionTransaction>> getHistory() async => const [];
}
