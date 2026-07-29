import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/notification_handler.dart';
import 'package:frontend/features/home/widgets/gymer_package_card.dart';
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

  test('personal program deep-link opens PT sent tab with exact id', () {
    final action = NotificationHandler().parseNotificationData({
      'type': 'coach_personal_program',
      'deepLink': 'gymer_personal_program:program-123',
    });

    expect(action.type, NotificationActionType.openGymerPrograms);
    expect(action.tabIndex, 1);
    expect(action.id, 'program-123');
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
