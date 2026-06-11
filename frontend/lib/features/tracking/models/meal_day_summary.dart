import 'meal_log_item.dart';

class MealDaySummary {
  MealDaySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.mealLogs,
    this.goalCompletionPercent,
    this.hasSnapshot = false,
    this.hasWarning = false,
    this.warningMessages = const [],
  });

  final String date;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final double? goalCompletionPercent;
  final bool hasSnapshot;
  final bool hasWarning;
  final List<String> warningMessages;
  final List<MealLogItem> mealLogs;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  factory MealDaySummary.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['mealLogs'];
    final rawWarnings = json['warningMessages'] ?? json['WarningMessages'];
    return MealDaySummary(
      date: (json['date'] ?? '').toString(),
      totalCalories: _asDouble(json['totalCalories']),
      totalProteinG: _asDouble(json['totalProteinG']),
      totalCarbsG: _asDouble(json['totalCarbsG']),
      totalFatG: _asDouble(json['totalFatG']),
      targetCalories: _asDouble(json['targetCalories']),
      targetProteinG: _asDouble(json['targetProteinG']),
      targetCarbsG: _asDouble(json['targetCarbsG']),
      targetFatG: _asDouble(json['targetFatG']),
      goalCompletionPercent: _asNullableDouble(
        json['goalCompletionPercent'] ?? json['GoalCompletionPercent'],
      ),
      hasSnapshot: json['hasSnapshot'] == true || json['HasSnapshot'] == true,
      hasWarning: json['hasWarning'] == true || json['HasWarning'] == true,
      warningMessages: rawWarnings is List
          ? rawWarnings.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      mealLogs: rawLogs is List
          ? rawLogs
              .whereType<Map<String, dynamic>>()
              .map(MealLogItem.fromJson)
              .toList()
          : [],
    );
  }
}
