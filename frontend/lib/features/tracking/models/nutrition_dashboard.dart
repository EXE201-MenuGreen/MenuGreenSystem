import 'meal_day_summary.dart';
import 'weight_log_item.dart';

class NutritionDashboard {
  NutritionDashboard({
    required this.range,
    required this.days,
    required this.weightLogs,
  });

  final String range;
  final List<MealDaySummary> days;
  final List<WeightLogItem> weightLogs;

  factory NutritionDashboard.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final rawWeightLogs = json['weightLogs'];
    return NutritionDashboard(
      range: (json['range'] ?? '').toString(),
      days: rawDays is List
          ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(MealDaySummary.fromJson)
              .toList()
          : [],
      weightLogs: rawWeightLogs is List
          ? rawWeightLogs
              .whereType<Map<String, dynamic>>()
              .map(WeightLogItem.fromJson)
              .toList()
          : [],
    );
  }
}
