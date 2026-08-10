import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/notification_handler.dart';
import 'package:frontend/features/home/widgets/gymer_package_card.dart';
import 'package:frontend/features/coach_chat/views/coach_chat_screen.dart';
import 'package:frontend/features/notifications/models/notification_models.dart';
import 'package:frontend/features/notifications/widgets/notification_tile.dart';

void main() {
  test('approval notification keeps raw type and approved status', () {
    final notification = AppNotification.fromJson({
      'id': 'notification-1',
      'title': 'Lộ trình đã được duyệt',
      'body': 'PT đã duyệt lộ trình của bạn',
      'type': 'meal_plan_approved',
      'isRead': false,
      'createdAt': '2026-07-27T10:00:00Z',
    });

    expect(notification.rawType, 'meal_plan_approved');
    expect(notification.normalizedType, 'meal_plan_approved');
    expect(notification.isRouteNotification, isTrue);
    expect(notification.statusLabel, 'Đã duyệt');
  });

  test('FCM custom data opens the correct route tab', () {
    final handler = NotificationHandler();

    final gymerAction = handler.parseNotificationData({
      'custom_data': 'meal_plan_approved|notification-1',
    });
    expect(gymerAction.type, NotificationActionType.openGymerPrograms);
    expect(gymerAction.tabIndex, 0);
    expect(gymerAction.id, isNull);

    final coachAction = handler.parseNotificationData({
      'custom_data': 'pt_review_request|notification-2',
    });
    expect(coachAction.type, NotificationActionType.openCoachWorkspace);
    expect(coachAction.tabIndex, 1);

    final weeklyReportAction = handler.parseNotificationData({
      'custom_data':
          'weekly_report_submitted|notification-3|'
          'coach_weekly_report:report-123',
    });
    expect(
      weeklyReportAction.type,
      NotificationActionType.openCoachWeeklyReport,
    );
    expect(weeklyReportAction.id, 'report-123');
  });

  test('route approval deep-link preserves the exact request id', () {
    final action = NotificationHandler().parseNotificationData({
      'type': 'meal_plan_approved',
      'id': 'notification-5',
      'deepLink': 'gymer_route_approval:route-request-123',
    });

    expect(action.type, NotificationActionType.openGymerPrograms);
    expect(action.tabIndex, 0);
    expect(action.id, 'route-request-123');
  });

  test('coach route notification opens the exact Gymer meal plan', () {
    final action = NotificationHandler().parseNotificationData({
      'type': 'pt_review_request',
      'deepLink': 'coach_route_approval:gymer-123:plan-456',
    });

    expect(action.type, NotificationActionType.openCoachMealPlan);
    expect(action.clientId, 'gymer-123');
    expect(action.id, 'plan-456');
  });

  test('coach route payload fields work without a deep-link', () {
    final action = NotificationHandler().parseNotificationData({
      'type': 'pt_review_request',
      'clientId': 'gymer-789',
      'mealPlanId': 'plan-999',
    });

    expect(action.type, NotificationActionType.openCoachMealPlan);
    expect(action.clientId, 'gymer-789');
    expect(action.id, 'plan-999');
  });

  test('personal program deep-link opens PT sent tab with exact id', () {
    final action = NotificationHandler().parseNotificationData({
      'type': 'coach_personal_program',
      'deepLink': 'gymer_personal_program:program-123',
    });

    expect(action.type, NotificationActionType.openGymerPrograms);
    expect(action.tabIndex, 1);
    expect(action.id, 'program-123');
  });

  test('chat notification opens the exact PT or Gymer conversation', () {
    final handler = NotificationHandler();
    final action = handler.parseNotificationData({
      'type': 'coach_chat_message',
      'deepLink': 'chat:partner-123',
    });

    expect(action.type, NotificationActionType.openCoachChat);
    expect(action.id, 'partner-123');
    final screen = handler.buildDestinationScreen(action);
    expect(screen, isA<CoachChatScreen>());
    expect((screen as CoachChatScreen).partnerId, 'partner-123');
  });

  test('chat actionUrl works for both PT and Gymer notification payloads', () {
    final handler = NotificationHandler();

    final ptAction = handler.parseNotificationData({
      'type': 'coach_chat_message',
      'actionUrl': 'chat:gymer-456',
    });
    final gymerAction = handler.parseNotificationData({
      'Type': 'COACH_CHAT_MESSAGE',
      'ActionUrl': 'chat:coach-789',
    });
    final fcmAction = handler.parseNotificationData({
      'custom_data': 'coach_chat_message|notification-1|chat:sender-from-fcm',
    });

    expect(ptAction.id, 'gymer-456');
    expect(gymerAction.id, 'coach-789');
    expect(fcmAction.id, 'sender-from-fcm');
  });

  test('weekly report notification exposes its status and deep-link', () {
    final notification = AppNotification.fromJson({
      'id': 'notification-4',
      'title': 'PT đã đánh giá báo cáo tuần',
      'body': 'Hãy xem nhận xét',
      'type': 'weekly_report_reviewed',
      'actionUrl': 'gymer_weekly_report:report-456',
      'isRead': false,
      'createdAt': '2026-07-27T10:00:00Z',
    });

    expect(notification.isWeeklyReportNotification, isTrue);
    expect(notification.statusLabel, 'Đã đánh giá');
    expect(notification.actionUrl, 'gymer_weekly_report:report-456');
  });

  test('meal-plan proposal notification opens the Gymer report area', () {
    final action = NotificationHandler().parseNotificationData({
      'type': 'meal_plan_proposal_deadline',
      'actionUrl': 'meal_plan_proposal:proposal-123',
    });

    expect(action.type, NotificationActionType.openGymerWeeklyReport);
  });

  testWidgets('route status and numeric badge are visible', (tester) async {
    final notification = AppNotification.fromJson({
      'id': 'notification-1',
      'title': 'Lộ trình đã được duyệt',
      'body': 'PT đã duyệt lộ trình của bạn',
      'type': 'meal_plan_approved',
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              NotificationTile(notification: notification),
              const GymerPackageCard(routeBadgeCount: 3),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Đã duyệt'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
