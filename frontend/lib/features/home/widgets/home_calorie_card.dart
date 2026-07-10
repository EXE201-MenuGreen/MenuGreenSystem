import 'package:flutter/material.dart';

import '../../meal_plan/widgets/calorie_progress_ring.dart';

class HomeCalorieCard extends StatelessWidget {
  const HomeCalorieCard({
    super.key,
    required this.totalCalories,
    required this.targetCalories,
    required this.protein,
    required this.targetProtein,
    required this.carbs,
    required this.targetCarbs,
    required this.fat,
    required this.targetFat,
    this.onTap,
  });

  final int totalCalories;
  final int targetCalories;
  final int protein;
  final int targetProtein;
  final int carbs;
  final int targetCarbs;
  final int fat;
  final int targetFat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TodayCaloriesCard(
      current: totalCalories,
      target: targetCalories,
      protein: protein,
      proteinTarget: targetProtein,
      carbs: carbs,
      carbsTarget: targetCarbs,
      fat: fat,
      fatTarget: targetFat,
      onTap: onTap,
    );
  }
}
