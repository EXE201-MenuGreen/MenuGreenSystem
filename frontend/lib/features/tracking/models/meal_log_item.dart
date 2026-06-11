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
