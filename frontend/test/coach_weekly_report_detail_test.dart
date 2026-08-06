import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/coach_pt/models/coach_report_models.dart';
import 'package:frontend/features/coach_pt/providers/coach_meal_plan_provider.dart';
import 'package:frontend/features/coach_pt/providers/coach_report_provider.dart';
import 'package:frontend/features/coach_pt/repositories/coach_meal_plan_repository.dart';
import 'package:frontend/features/coach_pt/repositories/coach_report_repository.dart';
import 'package:frontend/features/coach_pt/views/coach_create_meal_plan_screen.dart';
import 'package:frontend/features/coach_pt/views/coach_report_detail_screen.dart';
import 'package:provider/provider.dart';

class RecordingNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedRouteNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

class MockCoachReportRepository extends CoachReportRepository {
  MockCoachReportRepository({this.mockDetailPayload});

  final Map<String, dynamic>? mockDetailPayload;

  @override
  Future<CoachWeeklyReportDetail> getReportDetail(String reportId) async {
    final payload =
        mockDetailPayload ??
        {
          'reportId': reportId,
          'studentName': 'Nguyen Van A',
          'weekStartDate': '2026-08-03T00:00:00.000Z',
          'status': 'Pending',
          'createdAt': '2026-08-04T10:00:00.000Z',
          'ptComment': 'Đánh giá tốt',
          'suggestedChanges': [],
          'reportData': {
            'requestType': 'WeeklyReport',
            'weekStartDate': '2026-08-03',
            'dataThroughDate': '2026-08-04',
            'isPartial': true,
            'isFrozen': false,
            'checkInWeight': 70.5,
            'checkInBodyFat': 16.0,
            'trainingDaysCount': 3,
            'bodyFeeling': 'Khỏe',
            'studentNote': 'Cần giảm bớt mỡ',
            'nutritionSummary': {
              'totalActual': {'caloriesKcal': 3500.0, 'proteinG': 240.0},
              'totalPlanned': {'caloriesKcal': 4000.0, 'proteinG': 280.0},
            },
            'adherenceScore': {
              'overallScore': 85.0,
              'completedMealsCount': 6,
              'plannedMealsCount': 8,
              'skippedMealsCount': 1,
              'unplannedMealsCount': 1,
            },
            'dailyMeals': [
              {
                'date': '2026-08-03',
                'plannedItems': [
                  {
                    'id': 'item-1',
                    'mealType': 'breakfast',
                    'foodName': 'Mon ke hoach A',
                    'foodId': 'food-a',
                    'quantityG': 200,
                    'targetCalories': 330,
                    'proteinG': 62.0,
                    'isCompleted': true,
                  },
                ],
                'actualLogs': [
                  {
                    'id': 'log-1',
                    'mealType': 'lunch',
                    'foodName': 'Mon thuc te B',
                    'foodId': 'food-b',
                    'mealPlanItemId': 'item-1',
                    'quantityG': 150,
                    'caloriesKcal': 250.0,
                    'proteinG': 46.5,
                  },
                  {
                    'id': 'log-2',
                    'mealType': 'breakfast',
                    'foodName': 'Sinh tố bơ',
                    'mealPlanItemId': null,
                    'quantityG': 250,
                    'caloriesKcal': 300.0,
                    'proteinG': 4.0,
                  },
                ],
              },
              {
                'date': '2026-08-04',
                'plannedItems': [
                  {
                    'id': 'item-2',
                    'mealType': 'lunch',
                    'foodName': 'Cơm gạo lứt',
                    'quantityG': 150,
                    'targetCalories': 200,
                    'proteinG': 5.0,
                    'isCompleted': false,
                  },
                ],
                'actualLogs': [],
              },
            ],
          },
        };

    final summary = CoachWeeklyReport.fromJson(payload);
    return CoachWeeklyReportDetail.fromJson(summary, payload);
  }
}

class MockCoachMealPlanRepository extends CoachMealPlanRepository {
  @override
  Future<Map<String, dynamic>> getClientGymConfig(
    String clientId,
    DateTime date,
  ) async {
    return {
      'targetCalories': 2200,
      'minCalories': 1800,
      'maxCalories': 2400,
      'scope': 'custom',
    };
  }
}

void main() {
  test('CoachWeeklyReport parsing handles mid-week partial fields', () {
    final report = CoachWeeklyReport.fromJson({
      'reportId': 'rep-123',
      'studentName': 'Nguyen Van A',
      'weekStartDate': '2026-08-03T00:00:00.000Z',
      'status': 'Pending',
      'createdAt': '2026-08-04T10:00:00.000Z',
      'checkInWeight': 70.5,
      'trainingDaysCount': 3,
    });

    expect(report.reportId, 'rep-123');
    expect(report.studentName, 'Nguyen Van A');
    expect(report.isPending, isTrue);
    expect(report.checkInWeight, 70.5);
  });

  testWidgets(
    'CoachReportDetailScreen displays mid-week badge, meal stats, linked actual values, and unplanned logs',
    (tester) async {
      final mockRepo = MockCoachReportRepository();
      final provider = CoachReportProvider(repository: mockRepo);
      final navigatorObserver = RecordingNavigatorObserver();

      await tester.pumpWidget(
        ChangeNotifierProvider<CoachReportProvider>.value(
          value: provider,
          child: MaterialApp(
            navigatorObservers: [navigatorObserver],
            home: const CoachReportDetailScreen(reportId: 'rep-123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Báo cáo - Nguyen Van A'), findsOneWidget);
      expect(find.textContaining('Tạm tính đến'), findsOneWidget);
      expect(find.text('6/8'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));

      // Scroll down to reveal _DailyBreakdownCard
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Expand first ExpansionTile (Thứ Hai) to inspect items
      await tester.tap(find.textContaining('Thứ Hai'));
      await tester.pumpAndSettle();

      // The linked log is matched across the whole day even though its meal type
      // differs from the planned item's slot.
      expect(find.text('Mon thuc te B'), findsOneWidget);
      expect(find.textContaining('150g • 250 kcal'), findsOneWidget);
      expect(find.textContaining('Mon ke hoach A'), findsOneWidget);

      await tester.tap(find.text('Mon thuc te B'));
      expect(navigatorObserver.pushedRouteNames, contains('/foods/food-b'));

      // Assert unplanned log "Sinh tố bơ" is displayed with "Ngoài kế hoạch" badge
      expect(find.text('Sinh tố bơ'), findsOneWidget);
      expect(find.text('Ngoài kế hoạch'), findsWidgets);
    },
  );

  testWidgets(
    'CoachCreateMealPlanScreen creates valid protein range when initialTargetProtein > 100',
    (tester) async {
      final mockRepo = MockCoachMealPlanRepository();
      final provider = CoachMealPlanProvider(repository: mockRepo);

      await tester.pumpWidget(
        ChangeNotifierProvider<CoachMealPlanProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: CoachCreateMealPlanScreen(
              clientId: 'client-123',
              clientName: 'Nguyen Van A',
              initialPlanType: 'weekly',
              initialTargetCalories: 2200,
              initialTargetProtein: 140,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify protein text controller contains valid min protein bounds ('140')
      expect(find.text('140'), findsWidgets);
    },
  );
}
