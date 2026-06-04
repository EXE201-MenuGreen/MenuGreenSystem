import '../models/nutrition_models.dart';

/// Ngưỡng lệch macro so với mục tiêu (15%).
const double kMacroDeviationThreshold = 0.15;

class NutritionWarningMessages {
  NutritionWarningMessages._();

  static List<String> fromSummary(MealDaySummary summary) {
    final messages = <String>[];

    if (summary.hasWarning) {
      messages.add('Calo lệch hơn 10% so với mục tiêu ngày.');
    }

    final proteinMsg = _macroMessage(
      'Protein',
      summary.totalProteinG,
      summary.targetProteinG,
    );
    if (proteinMsg != null) messages.add(proteinMsg);

    final carbsMsg = _macroMessage(
      'Carb',
      summary.totalCarbsG,
      summary.targetCarbsG,
    );
    if (carbsMsg != null) messages.add(carbsMsg);

    final fatMsg = _macroMessage(
      'Chất béo',
      summary.totalFatG,
      summary.targetFatG,
    );
    if (fatMsg != null) messages.add(fatMsg);

    return messages;
  }

  static String? _macroMessage(String label, double total, double target) {
    if (target <= 0) return null;
    final deviation = (total - target).abs();
    if (deviation <= target * kMacroDeviationThreshold) return null;

    if (total > target) {
      return '$label vượt mục tiêu (${total.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g).';
    }
    return '$label thấp hơn mục tiêu (${total.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g).';
  }
}

/// Màu heatmap theo % đạt mục tiêu calo.
class NutritionHeatmapColors {
  NutritionHeatmapColors._();

  static double? goalPercentForDay(MealDaySummary day) {
    if (day.goalCompletionPercent != null) return day.goalCompletionPercent;
    if (day.targetCalories <= 0) return null;
    return day.totalCalories / day.targetCalories * 100;
  }

  /// null = không có dữ liệu.
  static HeatmapLevel levelForPercent(double? percent) {
    if (percent == null) return HeatmapLevel.none;
    if (percent >= 80 && percent <= 120) return HeatmapLevel.good;
    if ((percent >= 60 && percent < 80) || (percent > 120 && percent <= 140)) {
      return HeatmapLevel.moderate;
    }
    return HeatmapLevel.poor;
  }
}

enum HeatmapLevel { none, good, moderate, poor }
