import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/casual/views/casual_hub_screen.dart';
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
  const casualPlan = SubscriptionPlan(
    id: 'casual-plan',
    name: 'Gói Casual',
    durationDays: 30,
    priceVnd: 99000,
    isActive: true,
    tierLabel: 'Custom',
  );
  const gymPlan = SubscriptionPlan(
    id: 'gym-plan',
    name: 'Gói Gym/PT',
    durationDays: 30,
    priceVnd: 790000,
    featureGroup: 'gym',
    isActive: true,
    tierLabel: 'Custom',
  );
  const officePlan = SubscriptionPlan(
    id: 'office-plan',
    name: 'Gói Office',
    durationDays: 30,
    priceVnd: 99000,
    isActive: true,
    tierLabel: 'Custom',
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

  testWidgets('package cards render prices returned by the API', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UpgradePlanScreen(
          repository: _FakeSubscriptionRepository(
            plans: const [basicPlan, casualPlan, gymPlan, officePlan],
            current: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('99.000đ'), findsNWidgets(2));
    expect(find.text('790.000đ'), findsOneWidget);
    expect(find.text('0đ'), findsNothing);
    expect(find.text('Đang tải giá...'), findsNothing);
  });

  testWidgets('Casual hub renders its configured API price', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CasualHubScreen(
          subscriptionRepository: _FakeSubscriptionRepository(
            plans: const [casualPlan],
            current: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('99.000đ'), findsOneWidget);
    expect(find.textContaining('Đăng ký gói Casual • 99.000đ'), findsOneWidget);
    expect(find.text('0Đ'), findsNothing);
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
  Future<List<UserSubscription>> getActive() async => const [];

  @override
  Future<List<SubscriptionTransaction>> getHistory() async => const [];
}
