import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/gymer/widgets/route_approval_card.dart';

void main() {
  testWidgets('PT daily program is displayed as one day, not one week', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteApprovalCard(
            direction: 'received',
            request: {
              'id': 'program-1',
              'title': 'Lộ trình Ngày 30/07/2026',
              'planType': 'DAILY',
              'startDate': '2026-07-30',
              'endDate': '2026-07-30',
              'weekStartDate': '2026-07-30',
              'durationWeeks': 1,
              'status': 'Accepted',
            },
          ),
        ),
      ),
    );

    expect(find.text('Ngày 30/07/2026'), findsOneWidget);
    expect(find.text('1 ngày'), findsOneWidget);
    expect(find.text('1 tuần'), findsNothing);
  });

  testWidgets('Gymer weekly request keeps the sent-tab week label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteApprovalCard(
            direction: 'sent',
            request: {
              'reportId': 'request-1',
              'requestType': 'WeeklyReport',
              'weekStartDate': '2026-07-27',
              'status': 'Applied',
            },
          ),
        ),
      ),
    );

    expect(find.text('Báo cáo tuần'), findsOneWidget);
    expect(find.text('Tuần 27/07/2026'), findsOneWidget);
    expect(find.text('1 ngày'), findsNothing);
  });

  testWidgets('Gymer route approval is displayed as the requested day', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteApprovalCard(
            direction: 'sent',
            request: {
              'reportId': 'request-2',
              'requestType': 'RouteApproval',
              'weekStartDate': '2026-07-30',
              'status': 'Reviewed',
              'configuredCalorieTarget': 1500,
              'suggestedCalorieTarget': 2000,
            },
          ),
        ),
      ),
    );

    expect(find.text('Yêu cầu duyệt lộ trình'), findsOneWidget);
    expect(find.text('Ngày 30/07/2026'), findsOneWidget);
    expect(find.text('Tuần 30/07/2026'), findsNothing);
    expect(find.text('1500 kcal'), findsOneWidget);
    expect(find.text('2000 kcal'), findsNothing);
    expect(find.text('Duyệt thành công'), findsOneWidget);
    expect(find.text('Áp dụng gợi ý'), findsNothing);
  });

  testWidgets('Gymer route approval uses its weekly configuration period', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteApprovalCard(
            direction: 'sent',
            request: {
              'reportId': 'request-3',
              'requestType': 'RouteApproval',
              'configurationScope': 'week',
              'configurationStartDate': '2026-07-27',
              'configurationEndDate': '2026-08-02',
              'weekStartDate': '2026-07-31',
              'status': 'Pending',
            },
          ),
        ),
      ),
    );

    expect(find.text('Tuần 27/07/2026 - 02/08/2026'), findsOneWidget);
    expect(find.text('Ngày 31/07/2026'), findsNothing);
  });

  testWidgets('Gymer route approval uses its monthly configuration period', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteApprovalCard(
            direction: 'sent',
            request: {
              'reportId': 'request-4',
              'requestType': 'RouteApproval',
              'configurationScope': 'month',
              'configurationStartDate': '2026-07-01',
              'configurationEndDate': '2026-07-31',
              'weekStartDate': '2026-07-31',
              'status': 'Pending',
            },
          ),
        ),
      ),
    );

    expect(find.text('Tháng 07/2026'), findsOneWidget);
    expect(find.text('Ngày 31/07/2026'), findsNothing);
  });
}
