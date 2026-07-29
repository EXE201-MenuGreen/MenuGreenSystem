import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/gymer/models/route_approval_detail.dart';

void main() {
  test('parses PT note and planned meals from route report data', () {
    final detail = RouteApprovalDetail.fromJson({
      'reportId': 'request-1',
      'weekStartDate': '2026-07-27',
      'status': 'Reviewed',
      'ptComment': 'Ưu tiên rau xanh và uống đủ nước.',
      'suggestedCalorieTarget': 2000,
      'reportData': {
        'dailyMeals': [
          {
            'date': '2026-07-28',
            'plannedItems': [
              {
                'mealType': 'breakfast',
                'foodName': 'Bánh xèo miền Tây',
                'targetCalories': 520,
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
    expect(detail.suggestedCalorieTarget, 2000);
    expect(detail.days, hasLength(1));
    expect(detail.days.single.meals, hasLength(2));
    expect(detail.days.single.meals.first.mealType, 'breakfast');
    expect(detail.days.single.meals.first.name, 'Bánh xèo miền Tây');
    expect(detail.days.single.meals.last.name, 'Gà xào rau củ');
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
}
