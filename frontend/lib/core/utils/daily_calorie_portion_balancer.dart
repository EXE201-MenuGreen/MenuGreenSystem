class CaloriePortionInput {
  const CaloriePortionInput({
    required this.calories,
    required this.quantityG,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.ingredientQuantities = const [],
  });

  final double calories;
  final double quantityG;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<double> ingredientQuantities;
}

class BalancedCaloriePortion {
  const BalancedCaloriePortion({
    required this.calories,
    required this.quantityG,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.ingredientQuantities,
  });

  final int calories;
  final double quantityG;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<double> ingredientQuantities;
}

class DailyCalorieBalanceResult {
  const DailyCalorieBalanceResult({
    required this.originalCalories,
    required this.targetCalories,
    required this.scaleFactor,
    required this.portions,
  });

  final int originalCalories;
  final int targetCalories;
  final double scaleFactor;
  final List<BalancedCaloriePortion> portions;
}

/// Applies one common scale factor to every meal in a day, preserving the
/// original distribution between meals. The largest meal absorbs the integer
/// rounding remainder so the displayed total equals [targetCalories].
class DailyCaloriePortionBalancer {
  const DailyCaloriePortionBalancer._();

  static DailyCalorieBalanceResult balance({
    required List<CaloriePortionInput> portions,
    required int targetCalories,
  }) {
    if (portions.isEmpty) {
      throw ArgumentError.value(portions, 'portions', 'must not be empty');
    }
    if (targetCalories <= 0) {
      throw ArgumentError.value(
        targetCalories,
        'targetCalories',
        'must be positive',
      );
    }

    final currentCalories = portions.fold<double>(
      0,
      (sum, portion) => sum + portion.calories,
    );
    if (currentCalories <= 0) {
      throw ArgumentError('Total calories must be positive.');
    }

    final factor = targetCalories / currentCalories;
    final calorieValues = portions
        .map((portion) => (portion.calories * factor).round())
        .toList();
    final roundingDifference =
        targetCalories -
        calorieValues.fold<int>(0, (sum, value) => sum + value);
    if (roundingDifference != 0) {
      var largestIndex = 0;
      for (var index = 1; index < portions.length; index++) {
        if (portions[index].calories > portions[largestIndex].calories) {
          largestIndex = index;
        }
      }
      calorieValues[largestIndex] += roundingDifference;
    }

    return DailyCalorieBalanceResult(
      originalCalories: currentCalories.round(),
      targetCalories: targetCalories,
      scaleFactor: factor,
      portions: [
        for (var index = 0; index < portions.length; index++)
          BalancedCaloriePortion(
            calories: calorieValues[index],
            quantityG: portions[index].quantityG * factor,
            proteinG: portions[index].proteinG * factor,
            carbsG: portions[index].carbsG * factor,
            fatG: portions[index].fatG * factor,
            ingredientQuantities: portions[index].ingredientQuantities
                .map((quantity) => quantity * factor)
                .toList(),
          ),
      ],
    );
  }
}
