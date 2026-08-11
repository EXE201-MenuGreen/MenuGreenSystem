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
    this.customName,
    this.mealPlanItemId,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
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
  final String? customName;
  final String? mealPlanItemId;
  final double proteinG;
  final double carbsG;
  final double fatG;

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
    final loggedAtRaw = (json['loggedAt'] ?? json['LoggedAt'])?.toString();
    final foodName = (json['foodName'] ?? json['FoodName'])?.toString().trim();
    final recipeTitle = (json['recipeTitle'] ?? json['RecipeTitle'])
        ?.toString()
        .trim();
    final displayName = (json['displayName'] ?? json['DisplayName'])
        ?.toString()
        .trim();
    final customName = (json['customName'] ?? json['CustomName'])
        ?.toString()
        .trim();
    final notes = (json['notes'] ?? json['Notes'])?.toString().trim();

    final isValidDisplayName =
        displayName != null &&
        displayName.isNotEmpty &&
        displayName.toLowerCase() != 'logged item';

    final resolvedName = isValidDisplayName
        ? displayName
        : (foodName != null && foodName.isNotEmpty)
        ? foodName
        : (recipeTitle != null && recipeTitle.isNotEmpty)
        ? recipeTitle
        : (customName != null && customName.isNotEmpty)
        ? customName
        : (notes != null && notes.isNotEmpty)
        ? notes
        : 'Món đã ghi';

    return MealLogItem(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      mealType: (json['mealType'] ?? json['MealType'] ?? 'snack').toString(),
      quantityG: _asDouble(json['quantityG'] ?? json['QuantityG']),
      caloriesKcal: _asDouble(json['caloriesKcal'] ?? json['CaloriesKcal']),
      loggedAt: loggedAtRaw == null
          ? null
          : DateTime.tryParse(loggedAtRaw)?.toLocal(),
      displayName: resolvedName,
      foodId: _parseOptionalId(json['foodId'] ?? json['FoodId']),
      recipeId: _parseOptionalId(json['recipeId'] ?? json['RecipeId']),
      notes: json['notes']?.toString(),
      sourceType: json['sourceType']?.toString(),
      customName: customName,
      mealPlanItemId: _parseOptionalId(
        json['mealPlanItemId'] ?? json['MealPlanItemId'],
      ),
      proteinG: _asDouble(json['proteinG'] ?? json['ProteinG']),
      carbsG: _asDouble(json['carbsG'] ?? json['CarbsG']),
      fatG: _asDouble(json['fatG'] ?? json['FatG']),
    );
  }
}
