import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/gymer/views/personal_program_detail_screen.dart';
import 'package:frontend/features/meal_plan/repositories/meal_plan_repository.dart';
import 'package:frontend/features/tracking/repositories/nutrition_tracking_repository.dart';

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
                'quantityG': 180,
                'scheduledTime': '08:15:00',
              },
              {
                'plannedDate': '2026-07-27',
                'mealType': 'lunch',
                'recipeName': 'Cơm gà rau củ',
                'targetCalories': 620,
                'scheduledTime': '12:45',
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
    expect(find.textContaining('180 g · 480 kcal'), findsOneWidget);
    expect(find.text('Giờ ăn: 08:15'), findsOneWidget);
    expect(find.text('Giờ ăn: 12:45'), findsOneWidget);
    expect(find.text('Ăn đúng khung giờ.'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
    expect(find.text('Chấp nhận lộ trình'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepted meal is checked only after meal log API succeeds', (
    tester,
  ) async {
    final mealPlanRepository = _FakeMealPlanRepository();

    await _pumpAcceptedProgram(
      tester,
      mealPlanRepository: mealPlanRepository,
      nutritionRepository: _FakeNutritionRepository(),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(mealPlanRepository.toggleCalls, [('meal-1', true)]);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('failed meal log API leaves meal unchecked and shows error', (
    tester,
  ) async {
    final mealPlanRepository = _FakeMealPlanRepository(shouldFail: true);

    await _pumpAcceptedProgram(
      tester,
      mealPlanRepository: mealPlanRepository,
      nutritionRepository: _FakeNutritionRepository(),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(mealPlanRepository.toggleCalls, [('meal-1', true)]);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('future personal-program meal cannot be marked as eaten', (
    tester,
  ) async {
    final mealPlanRepository = _FakeMealPlanRepository();

    await _pumpAcceptedProgram(
      tester,
      plannedDate: '2999-01-01',
      mealPlanRepository: mealPlanRepository,
      nutritionRepository: _FakeNutritionRepository(),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    expect(mealPlanRepository.toggleCalls, isEmpty);
  });

  testWidgets('existing linked meal log restores the checked state', (
    tester,
  ) async {
    await _pumpAcceptedProgram(
      tester,
      mealPlanRepository: _FakeMealPlanRepository(),
      nutritionRepository: _FakeNutritionRepository(loggedMealIds: {'meal-1'}),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}

Future<void> _pumpAcceptedProgram(
  WidgetTester tester, {
  String plannedDate = '2020-01-01',
  required MealPlanRepository mealPlanRepository,
  required NutritionTrackingRepository nutritionRepository,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: PersonalProgramDetailScreen(
        mealPlanRepository: mealPlanRepository,
        nutritionTrackingRepository: nutritionRepository,
        program: {
          'id': 'program-1',
          'title': 'Lộ trình từ PT',
          'planType': 'DAILY',
          'startDate': plannedDate,
          'endDate': plannedDate,
          'targetCaloriesDaily': 1800,
          'status': 'Accepted',
          'acceptedAt': '2020-01-01T00:00:00Z',
          'meals': [
            {
              'id': 'meal-1',
              'plannedDate': plannedDate,
              'mealType': 'breakfast',
              'foodId': 'food-1',
              'foodName': 'Phở gà',
              'targetCalories': 480,
              'isCompleted': false,
            },
          ],
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeMealPlanRepository extends MealPlanRepository {
  _FakeMealPlanRepository({this.shouldFail = false});

  final bool shouldFail;
  final List<(String, bool)> toggleCalls = [];

  @override
  Future<void> toggleItem(String itemId, bool isCompleted) async {
    toggleCalls.add((itemId, isCompleted));
    if (shouldFail) throw Exception('meal log failed');
  }
}

class _FakeNutritionRepository extends NutritionTrackingRepository {
  _FakeNutritionRepository({this.loggedMealIds = const <String>{}});

  final Set<String> loggedMealIds;

  @override
  Future<MealDaySummary?> getDailySummary(DateTime date) async {
    return MealDaySummary(
      date:
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      totalCalories: 0,
      totalProteinG: 0,
      totalCarbsG: 0,
      totalFatG: 0,
      targetCalories: 1800,
      targetProteinG: 120,
      targetCarbsG: 220,
      targetFatG: 60,
      mealLogs: loggedMealIds
          .map(
            (mealId) => MealLogItem(
              id: 'log-$mealId',
              mealType: 'breakfast',
              quantityG: 100,
              caloriesKcal: 480,
              loggedAt: date,
              displayName: 'Phở gà',
              mealPlanItemId: mealId,
            ),
          )
          .toList(),
    );
  }
}
