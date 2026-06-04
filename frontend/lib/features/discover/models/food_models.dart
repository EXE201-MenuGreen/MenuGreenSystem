class FoodItem {
  FoodItem({
    required this.id,
    required this.nameVi,
    this.nameEn,
    this.category,
    this.description,
    this.caloriesKcal,
    this.proteinG,
    this.estimatedPriceVnd,
    this.imageUrl,
    this.allergenLabelsVi = const [],
    this.matchedAllergens = const [],
    this.allergyRiskLevel = 'none',
    this.isSafeForUser = true,
  });

  final String id;
  final String nameVi;
  final String? nameEn;
  final String? category;
  final String? description;
  final double? caloriesKcal;
  final double? proteinG;
  final int? estimatedPriceVnd;
  final String? imageUrl;
  final List<String> allergenLabelsVi;
  final List<String> matchedAllergens;
  final String allergyRiskLevel;
  final bool isSafeForUser;

  static double? _num(dynamic v) => v is num ? v.toDouble() : null;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    List<String> listOf(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return FoodItem(
      id: (json['id'] ?? json['Id']).toString(),
      nameVi: (json['nameVi'] ?? json['NameVi'] ?? '').toString(),
      nameEn: json['nameEn']?.toString() ?? json['NameEn']?.toString(),
      category: json['category']?.toString() ?? json['Category']?.toString(),
      description: json['description']?.toString() ?? json['Description']?.toString(),
      caloriesKcal: _num(json['caloriesKcal'] ?? json['CaloriesKcal']),
      proteinG: _num(json['proteinG'] ?? json['ProteinG']),
      estimatedPriceVnd: json['estimatedPriceVnd'] is int
          ? json['estimatedPriceVnd'] as int
          : (json['EstimatedPriceVnd'] is int ? json['EstimatedPriceVnd'] as int : null),
      imageUrl: json['imageUrl']?.toString() ?? json['ImageUrl']?.toString(),
      allergenLabelsVi: listOf(json['allergenLabelsVi'] ?? json['AllergenLabelsVi']),
      matchedAllergens: listOf(json['matchedAllergens'] ?? json['MatchedAllergens']),
      allergyRiskLevel: (json['allergyRiskLevel'] ?? json['AllergyRiskLevel'] ?? 'none').toString(),
      isSafeForUser: (json['isSafeForUser'] ?? json['IsSafeForUser']) != false,
    );
  }
}

class RecipeItem {
  RecipeItem({
    required this.id,
    required this.title,
    this.description,
    this.prepTimeMin,
    this.mealType,
    this.ingredients = const [],
    this.matchedAllergens = const [],
    this.allergyRiskLevel = 'none',
    this.isSafeForUser = true,
  });

  final String id;
  final String title;
  final String? description;
  final int? prepTimeMin;
  final String? mealType;
  final List<RecipeIngredientItem> ingredients;
  final List<String> matchedAllergens;
  final String allergyRiskLevel;
  final bool isSafeForUser;

  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] ?? json['Ingredients'];
    List<String> listOf(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return RecipeItem(
      id: (json['id'] ?? json['Id']).toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: json['description']?.toString() ?? json['Description']?.toString(),
      prepTimeMin: json['prepTimeMin'] is int
          ? json['prepTimeMin'] as int
          : (json['PrepTimeMin'] is int ? json['PrepTimeMin'] as int : null),
      mealType: json['mealType']?.toString() ?? json['MealType']?.toString(),
      ingredients: rawIngredients is List
          ? rawIngredients
              .whereType<Map<String, dynamic>>()
              .map(RecipeIngredientItem.fromJson)
              .toList()
          : [],
      matchedAllergens: listOf(json['matchedAllergens'] ?? json['MatchedAllergens']),
      allergyRiskLevel: (json['allergyRiskLevel'] ?? json['AllergyRiskLevel'] ?? 'none').toString(),
      isSafeForUser: (json['isSafeForUser'] ?? json['IsSafeForUser']) != false,
    );
  }
}

class IngredientItem {
  IngredientItem({
    required this.id,
    required this.nameVi,
    this.category,
    this.caloriesKcal,
    this.unitDefault,
  });

  final String id;
  final String nameVi;
  final String? category;
  final double? caloriesKcal;
  final String? unitDefault;

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    final c = json['caloriesKcal'] ?? json['CaloriesKcal'];
    return IngredientItem(
      id: (json['id'] ?? json['Id']).toString(),
      nameVi: (json['nameVi'] ?? json['NameVi'] ?? '').toString(),
      category: json['category']?.toString() ?? json['Category']?.toString(),
      caloriesKcal: c is num ? c.toDouble() : null,
      unitDefault: json['unitDefault']?.toString() ?? json['UnitDefault']?.toString(),
    );
  }
}

class RecipeIngredientItem {
  RecipeIngredientItem({
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  final String ingredientName;
  final double quantity;
  final String unit;
  final String? notes;

  factory RecipeIngredientItem.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'] ?? json['Quantity'];
    return RecipeIngredientItem(
      ingredientName: (json['ingredientName'] ?? json['IngredientName'] ?? '').toString(),
      quantity: q is num ? q.toDouble() : 0,
      unit: (json['unit'] ?? json['Unit'] ?? '').toString(),
      notes: json['notes']?.toString() ?? json['Notes']?.toString(),
    );
  }
}

class FavoriteFoodItem {
  FavoriteFoodItem({
    required this.foodId,
    required this.nameVi,
    this.caloriesKcal,
    this.imageUrl,
  });

  final String foodId;
  final String nameVi;
  final double? caloriesKcal;
  final String? imageUrl;

  factory FavoriteFoodItem.fromJson(Map<String, dynamic> json) {
    final c = json['caloriesKcal'] ?? json['CaloriesKcal'];
    return FavoriteFoodItem(
      foodId: (json['foodId'] ?? json['FoodId']).toString(),
      nameVi: (json['nameVi'] ?? json['NameVi'] ?? '').toString(),
      caloriesKcal: c is num ? c.toDouble() : null,
      imageUrl: json['imageUrl']?.toString() ?? json['ImageUrl']?.toString(),
    );
  }
}
