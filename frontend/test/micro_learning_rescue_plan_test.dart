import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/micro_learning/models/micro_learning_models.dart';

void main() {
  test('maps a rescue food to a pending custom meal-plan item', () {
    const food = RescueFood(
      name: 'Súp nấm hạt sen gà xé',
      caloriesKcal: 250,
      proteinG: 22,
      carbsG: 28,
      fatG: 5.5,
      estimatedPriceVnd: 45000,
      description: 'Món gợi ý khi căng thẳng.',
    );

    final payload = food.toPlanMealJson('Dinner');
    expect(payload, {
      'mealType': 'Dinner',
      'customName': 'Súp nấm hạt sen gà xé',
      'quantityG': 100,
      'caloriesKcal': 250,
      'proteinG': 22,
      'carbsG': 28,
      'fatG': 5.5,
    });
    expect(payload.containsKey('foodId'), isFalse);
    expect(payload.containsKey('isCompleted'), isFalse);
  });
}
