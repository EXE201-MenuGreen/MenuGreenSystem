import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/gymer/views/personal_program_detail_screen.dart';

void main() {
  testWidgets('Gymer sees scoped kcal, meals and acceptance actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PersonalProgramDetailScreen(
          program: {
            'id': 'program-1',
            'title': 'Lộ trình tuần từ PT',
            'description': 'Thực đơn kiểm thử',
            'planType': 'WEEKLY',
            'startDate': '2026-07-27',
            'endDate': '2026-08-02',
            'durationWeeks': 1,
            'targetCaloriesDaily': 1800,
            'minCalories': 350,
            'maxCalories': 650,
            'targetProteinG': 120,
            'targetCarbsG': 220,
            'targetFatG': 60,
            'coachComment': 'Ăn đúng khung giờ.',
            'status': 'Pending',
            'meals': [
              {
                'plannedDate': '2026-07-27',
                'mealType': 'breakfast',
                'foodName': 'Phở gà',
                'targetCalories': 480,
              },
              {
                'plannedDate': '2026-07-27',
                'mealType': 'lunch',
                'recipeName': 'Cơm gà rau củ',
                'targetCalories': 620,
              },
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1800 kcal'), findsOneWidget);
    expect(find.text('350 kcal'), findsOneWidget);
    expect(find.text('650 kcal'), findsOneWidget);
    expect(find.text('Phở gà'), findsOneWidget);
    expect(find.text('Cơm gà rau củ'), findsOneWidget);
    expect(find.text('Ăn đúng khung giờ.'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
    expect(find.text('Chấp nhận lộ trình'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
