import 'package:flutter/material.dart';

import '../../../core/utils/nutrition_format.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';

class WeeklyPlanDayCard extends StatelessWidget {
  const WeeklyPlanDayCard({super.key, required this.day, this.onMealTap});

  final WeeklyPlanDay day;
  final void Function(DailyMenuPlanItem)? onMealTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (day.meals.isEmpty) _buildEmptyState() else _buildMealsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isToday = _isToday(day.date);
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayName = weekdays[day.date.weekday - 1];

    return Row(
      children: [
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'HÔM NAY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        if (isToday) const SizedBox(width: 8),
        Text(
          'Thứ $dayName',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isToday ? AppColors.primary : AppColors.textDark,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${day.date.day}/${day.date.month}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${day.totalCalories} kcal',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            'Chưa có kế hoạch bữa ăn',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    final groupedMeals = <String, List<DailyMenuPlanItem>>{};
    for (final meal in day.meals) {
      groupedMeals.putIfAbsent(meal.mealType, () => []).add(meal);
    }

    return Column(
      children: groupedMeals.entries.map((entry) {
        return _buildMealTypeSection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildMealTypeSection(String mealType, List<DailyMenuPlanItem> meals) {
    final totalCal = meals.fold<int>(0, (sum, m) => sum + m.targetCalories);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getMealTypeIcon(mealType),
              const SizedBox(width: 8),
              Text(
                _formatMealType(mealType),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '$totalCal kcal',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...meals.map((meal) => _buildMealItem(meal)),
        ],
      ),
    );
  }

  Widget _buildMealItem(DailyMenuPlanItem meal) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4),
      child: InkWell(
        onTap: onMealTap == null ? null : () => onMealTap!(meal),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                meal.isFood ? Icons.restaurant : Icons.menu_book,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meal.recommendation != null)
                      Text(
                        formatNutritionFacts(
                          quantityG: meal.quantityG,
                          caloriesKcal: meal.targetCalories,
                          proteinG: meal.recommendation!.proteinG,
                          carbsG: meal.recommendation!.carbsG,
                          fatG: meal.recommendation!.fatG,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (onMealTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getMealTypeIcon(String mealType) {
    IconData icon;
    Color color;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        icon = Icons.wb_sunny_outlined;
        color = Colors.orange;
        break;
      case 'lunch':
        icon = Icons.lunch_dining;
        color = Colors.blue;
        break;
      case 'dinner':
        icon = Icons.dinner_dining;
        color = Colors.purple;
        break;
      case 'snack':
        icon = Icons.cookie;
        color = Colors.brown;
        break;
      default:
        icon = Icons.restaurant;
        color = AppColors.primary;
    }

    return Icon(icon, size: 18, color: color);
  }

  String _formatMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Bữa phụ';
      default:
        return mealType;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
