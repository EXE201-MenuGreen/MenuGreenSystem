import 'package:flutter/material.dart';

enum MealCategory {
  breakfast,
  lunch,
  dinner,
  snack,
}

extension MealCategoryX on MealCategory {
  String get label => switch (this) {
        MealCategory.breakfast => 'Bữa sáng',
        MealCategory.lunch => 'Bữa trưa',
        MealCategory.dinner => 'Bữa tối',
        MealCategory.snack => 'Bữa phụ',
      };

  String get filterLabel => label;

  IconData get icon => switch (this) {
        MealCategory.breakfast => Icons.wb_sunny_outlined,
        MealCategory.lunch => Icons.restaurant_outlined,
        MealCategory.dinner => Icons.dinner_dining_outlined,
        MealCategory.snack => Icons.cookie_outlined,
      };
}

class HistoryMealEntry {
  const HistoryMealEntry({
    required this.id,
    required this.title,
    required this.calories,
    required this.portion,
    required this.time,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String title;
  final int calories;
  final String portion;
  final TimeOfDay time;
  final MealCategory category;
  final String? imageUrl;
}

class HistoryTimelineSection {
  const HistoryTimelineSection({
    required this.category,
    required this.time,
    required this.meals,
    this.isHighlighted = false,
  });

  final MealCategory category;
  final TimeOfDay time;
  final List<HistoryMealEntry> meals;
  final bool isHighlighted;
}
