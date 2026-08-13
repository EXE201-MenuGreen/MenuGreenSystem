import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/advanced/views/advanced_detail_screens.dart';
import 'package:frontend/features/gymer/models/route_approval_detail.dart';
import 'package:frontend/features/gymer/utils/route_approval_period.dart';

void main() {
  test('parses PT note and planned meals from route report data', () {
    final detail = RouteApprovalDetail.fromJson({
      'reportId': 'request-1',
      'requestType': 'RouteApproval',
      'weekStartDate': '2026-07-27',
      'createdAt': '2026-07-30T05:47:00Z',
      'status': 'Reviewed',
      'ptComment': 'Ưu tiên rau xanh và uống đủ nước.',
      'suggestedCalorieTarget': 2000,
      'configuredCalorieTarget': 1500,
      'configuredMinCalories': 500,
      'configuredMaxCalories': 1500,
      'configurationScope': 'day',
      'configurationStartDate': '2026-07-30',
      'configurationEndDate': '2026-07-30',
      'reportData': {
        'mealPlanId': 'plan-current-1',
        'studentHealthProfile': {
          'targetProteinG': 122,
          'targetCarbsG': 200,
          'targetFatG': 67,
        },
        'dailyMeals': [
          {
            'date': '2026-07-28',
            'plannedItems': [
              {
                'id': 'meal-1',
                'mealType': 'breakfast',
                'foodName': 'Bánh xèo miền Tây',
                'plannedDate': '2026-07-28',
                'scheduledTime': '07:30:00',
                'targetCalories': 520,
                'quantityG': 180,
                'isCompleted': true,
              },
              {
                'mealType': 'lunch',
                'recipeName': 'Gà xào rau củ',
                'targetCalories': 650,
              },
            ],
          },
        ],
      },
    });

    expect(detail.ptComment, 'Ưu tiên rau xanh và uống đủ nước.');
    expect(detail.requestType, 'RouteApproval');
    expect(detail.mealPlanId, 'plan-current-1');
    expect(detail.createdAt, DateTime.utc(2026, 7, 30, 5, 47));
    expect(detail.suggestedCalorieTarget, 2000);
    expect(detail.configuredCalorieTarget, 1500);
    expect(detail.configuredMinCalories, 500);
    expect(detail.configuredMaxCalories, 1500);
    expect(detail.configurationScope, 'day');
    expect(detail.configurationStartDate, DateTime(2026, 7, 30));
    expect(detail.configurationEndDate, DateTime(2026, 7, 30));
    expect(detail.targetProteinG, 122);
    expect(detail.days, hasLength(1));
    expect(detail.days.single.meals, hasLength(2));
    expect(detail.days.single.meals.first.mealType, 'breakfast');
    expect(detail.days.single.meals.first.id, 'meal-1');
    expect(detail.days.single.meals.first.isCompleted, isTrue);
    expect(detail.days.single.meals.first.name, 'Bánh xèo miền Tây');
    expect(detail.days.single.meals.first.plannedDate, DateTime(2026, 7, 28));
    expect(detail.days.single.meals.first.scheduledTime, '07:30:00');
    expect(detail.days.single.meals.first.quantityG, 180);
    expect(detail.days.single.meals.last.name, 'Gà xào rau củ');
    expect(detail.plannedCaloriesPerDay, 1170);
  });

  test('uses approved meal calories instead of configured calorie target', () {
    final detail = RouteApprovalDetail.fromJson({
      'reportId': 'request-1889',
      'configuredCalorieTarget': 2000,
      'reportData': {
        'dailyMeals': [
          {
            'date': '2026-08-13',
            'plannedItems': [
              {'mealType': 'breakfast', 'targetCalories': 505},
              {'mealType': 'lunch', 'targetCalories': 414},
              {'mealType': 'dinner', 'targetCalories': 550},
              {'mealType': 'snack', 'targetCalories': 420},
            ],
          },
        ],
      },
    });

    expect(detail.configuredCalorieTarget, 2000);
    expect(detail.plannedCaloriesPerDay, 1889);
  });

  test('accepts PascalCase payloads returned by legacy endpoints', () {
    final detail = RouteApprovalDetail.fromJson({
      'ReportId': 'request-2',
      'WeekStartDate': '2026-07-20',
      'Status': 'Applied',
      'PtComment': 'Giữ đúng khẩu phần.',
      'ReportData': {
        'DailyMeals': [
          {
            'Date': '2026-07-20',
            'PlannedItems': [
              {
                'MealType': 'dinner',
                'RecipeName': 'Canh chua tôm',
                'TargetCalories': 600,
              },
            ],
          },
        ],
      },
    });

    expect(detail.requestId, 'request-2');
    expect(detail.days.single.meals.single.name, 'Canh chua tôm');
    expect(detail.days.single.meals.single.calories, 600);
  });

  test('route request only matches its exact selected date', () {
    final request = <String, dynamic>{
      'weekStartDate': '2026-07-30',
      'createdAt': '2026-07-30T05:47:00Z',
    };

    expect(routeRequestMatchesDate(request, DateTime(2026, 7, 30)), isTrue);
    expect(routeRequestMatchesDate(request, DateTime(2026, 7, 29)), isFalse);
  });

  test('legacy route request uses its creation day instead of week Monday', () {
    final request = <String, dynamic>{
      'weekStartDate': '2026-07-27',
      'createdAt': '2026-07-30T05:47:00',
    };

    expect(routeRequestMatchesDate(request, DateTime(2026, 7, 30)), isTrue);
  });

  test('configuration period labels follow day, week, and month scopes', () {
    final date = DateTime(2026, 7, 31);

    expect(
      RouteApprovalPeriod.periodLabel(scope: 'day', start: date, end: date),
      'Ngày 31/07/2026',
    );
    expect(RouteApprovalPeriod.durationLabel('day'), '1 ngày');

    expect(
      RouteApprovalPeriod.periodLabel(
        scope: 'week',
        start: DateTime(2026, 7, 27),
        end: DateTime(2026, 8, 2),
      ),
      'Tuần 27/07/2026 - 02/08/2026',
    );
    expect(RouteApprovalPeriod.durationLabel('week'), '1 tuần');

    expect(
      RouteApprovalPeriod.periodLabel(
        scope: 'month',
        start: DateTime(2026, 7),
        end: DateTime(2026, 7, 31),
      ),
      'Tháng 07/2026',
    );
    expect(RouteApprovalPeriod.durationLabel('month'), '1 tháng');
  });
}
