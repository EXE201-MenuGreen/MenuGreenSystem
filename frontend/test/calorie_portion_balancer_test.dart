import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/daily_calorie_portion_balancer.dart';

void main() {
  group('DailyCaloriePortionBalancer', () {
    test(
      'increases all portions proportionally when calories are under target',
      () {
        final result = DailyCaloriePortionBalancer.balance(
          targetCalories: 2000,
          portions: const [
            CaloriePortionInput(
              calories: 400,
              quantityG: 200,
              proteinG: 20,
              carbsG: 40,
              fatG: 10,
              ingredientQuantities: [100, 100],
            ),
            CaloriePortionInput(
              calories: 600,
              quantityG: 300,
              proteinG: 30,
              carbsG: 60,
              fatG: 15,
            ),
            CaloriePortionInput(
              calories: 500,
              quantityG: 250,
              proteinG: 25,
              carbsG: 50,
              fatG: 12,
            ),
            CaloriePortionInput(
              calories: 300,
              quantityG: 150,
              proteinG: 15,
              carbsG: 30,
              fatG: 8,
            ),
          ],
        );

        expect(result.originalCalories, 1800);
        expect(result.scaleFactor, closeTo(2000 / 1800, 0.000001));
        expect(
          result.portions.fold<int>(
            0,
            (sum, portion) => sum + portion.calories,
          ),
          2000,
        );
        expect(result.portions.first.quantityG, closeTo(222.22, 0.01));
        expect(result.portions.first.proteinG, closeTo(22.22, 0.01));
        expect(
          result.portions.first.ingredientQuantities.first,
          closeTo(111.11, 0.01),
        );
      },
    );

    test(
      'decreases all portions proportionally when calories exceed target',
      () {
        final result = DailyCaloriePortionBalancer.balance(
          targetCalories: 2000,
          portions: const [
            CaloriePortionInput(
              calories: 600,
              quantityG: 300,
              proteinG: 30,
              carbsG: 60,
              fatG: 15,
            ),
            CaloriePortionInput(
              calories: 700,
              quantityG: 350,
              proteinG: 35,
              carbsG: 70,
              fatG: 18,
            ),
            CaloriePortionInput(
              calories: 500,
              quantityG: 250,
              proteinG: 25,
              carbsG: 50,
              fatG: 12,
            ),
            CaloriePortionInput(
              calories: 600,
              quantityG: 300,
              proteinG: 30,
              carbsG: 60,
              fatG: 15,
            ),
          ],
        );

        expect(result.originalCalories, 2400);
        expect(result.scaleFactor, closeTo(5 / 6, 0.000001));
        expect(
          result.portions.fold<int>(
            0,
            (sum, portion) => sum + portion.calories,
          ),
          2000,
        );
        expect(result.portions[1].quantityG, closeTo(291.67, 0.01));
        expect(result.portions[1].calories, 583);
      },
    );

    test('rejects a day whose calorie total is zero', () {
      expect(
        () => DailyCaloriePortionBalancer.balance(
          targetCalories: 2000,
          portions: const [
            CaloriePortionInput(
              calories: 0,
              quantityG: 100,
              proteinG: 0,
              carbsG: 0,
              fatG: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
