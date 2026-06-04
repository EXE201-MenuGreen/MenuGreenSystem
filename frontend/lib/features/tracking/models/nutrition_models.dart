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
      mealLogs: rawLogs is List
          ? rawLogs
              .whereType<Map<String, dynamic>>()
              .map(MealLogItem.fromJson)
              .toList()
          : [],
    );
  }
}

class MealLogItem {
  MealLogItem({
    required this.id,
    required this.mealType,
    required this.quantityG,
    required this.caloriesKcal,
    required this.loggedAt,
    required this.displayName,
    this.foodId,
    this.recipeId,
    this.notes,
    this.sourceType,
  });

  final String id;
  final String mealType;
  final double quantityG;
  final double caloriesKcal;
  final DateTime? loggedAt;
  final String displayName;
  final String? foodId;
  final String? recipeId;
  final String? notes;
  final String? sourceType;

  bool get isRecipe =>
      (recipeId != null && recipeId!.isNotEmpty) ||
      sourceType?.toLowerCase() == 'recipe';

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static String? _parseOptionalId(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    if (text == '00000000-0000-0000-0000-000000000000') return null;
    return text;
  }

  factory MealLogItem.fromJson(Map<String, dynamic> json) {
    final loggedAtRaw = json['loggedAt']?.toString();
    final foodName = json['foodName']?.toString().trim();
    final recipeTitle = json['recipeTitle']?.toString().trim();
    final displayName = json['displayName']?.toString().trim();
    final resolvedName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (foodName != null && foodName.isNotEmpty)
            ? foodName
            : (recipeTitle != null && recipeTitle.isNotEmpty)
                ? recipeTitle
                : 'Món đã ghi';

    return MealLogItem(
      id: (json['id'] ?? '').toString(),
      mealType: (json['mealType'] ?? 'snack').toString(),
      quantityG: _asDouble(json['quantityG']),
      caloriesKcal: _asDouble(json['caloriesKcal']),
      loggedAt: loggedAtRaw == null ? null : DateTime.tryParse(loggedAtRaw)?.toLocal(),
      displayName: resolvedName,
      foodId: _parseOptionalId(json['foodId'] ?? json['FoodId']),
      recipeId: _parseOptionalId(json['recipeId'] ?? json['RecipeId']),
      notes: json['notes']?.toString(),
      sourceType: json['sourceType']?.toString(),
    );
  }
}

class WeightLogItem {
  WeightLogItem({
    required this.id,
    required this.weightKg,
    required this.bodyFatPercent,
    required this.recordedAt,
  });

  final String id;
  final double weightKg;
  final double? bodyFatPercent;
  final DateTime? recordedAt;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  factory WeightLogItem.fromJson(Map<String, dynamic> json) {
    final recordedAtRaw = json['recordedAt']?.toString();
    return WeightLogItem(
      id: (json['id'] ?? '').toString(),
      weightKg: _asDouble(json['weightKg']),
      bodyFatPercent: _asNullableDouble(json['bodyFatPercent']),
      recordedAt:
          recordedAtRaw == null ? null : DateTime.tryParse(recordedAtRaw)?.toLocal(),
    );
  }
}

class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory CatalogItem.fromJson(
    Map<String, dynamic> json, {
    required String fallbackNameKey,
  }) {
    final name = (json[fallbackNameKey] ??
            json['nameVi'] ??
            json['title'] ??
            json['name'] ??
            '')
        .toString();
    return CatalogItem(
      id: (json['id'] ?? '').toString(),
      name: name.isEmpty ? 'Không tên' : name,
    );
  }
}
