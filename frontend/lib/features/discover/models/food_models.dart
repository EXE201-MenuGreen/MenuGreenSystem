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
    this.matchedAllergens = const [],
    this.allergyRiskLevel = 'none',
    this.isSafeForUser = true,
  });

  final String id;
  final String nameVi;
  final String? category;
  final double? caloriesKcal;
  final String? unitDefault;
  final List<String> matchedAllergens;
  final String allergyRiskLevel;
  final bool isSafeForUser;

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    final c = json['caloriesKcal'] ?? json['CaloriesKcal'];
    List<String> listOf(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return IngredientItem(
      id: (json['id'] ?? json['Id']).toString(),
      nameVi: (json['nameVi'] ?? json['NameVi'] ?? '').toString(),
      category: json['category']?.toString() ?? json['Category']?.toString(),
      caloriesKcal: c is num ? c.toDouble() : null,
      unitDefault: json['unitDefault']?.toString() ?? json['UnitDefault']?.toString(),
      matchedAllergens: listOf(json['matchedAllergens'] ?? json['MatchedAllergens']),
      allergyRiskLevel: (json['allergyRiskLevel'] ?? json['AllergyRiskLevel'] ?? 'none').toString(),
      isSafeForUser: (json['isSafeForUser'] ?? json['IsSafeForUser']) != false,
    );
  }
}

class IngredientRecipeLink {
  IngredientRecipeLink({
    required this.recipeId,
    required this.title,
    this.prepTimeMin,
    this.mealType,
  });

  final String recipeId;
  final String title;
  final int? prepTimeMin;
  final String? mealType;

  factory IngredientRecipeLink.fromJson(Map<String, dynamic> json) {
    return IngredientRecipeLink(
      recipeId: (json['recipeId'] ?? json['RecipeId']).toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      prepTimeMin: json['prepTimeMin'] is int
          ? json['prepTimeMin'] as int
          : (json['PrepTimeMin'] is int ? json['PrepTimeMin'] as int : null),
      mealType: json['mealType']?.toString() ?? json['MealType']?.toString(),
    );
  }
}

class RecommendationItem {
  RecommendationItem({
    required this.id,
    required this.name,
    required this.type,
    required this.caloriesKcal,
    required this.proteinG,
    required this.estimatedPriceVnd,
    required this.cookingTimeMin,
    required this.score,
  });

  final String id;
  final String name;
  final String type;
  final double caloriesKcal;
  final double proteinG;
  final int estimatedPriceVnd;
  final int cookingTimeMin;
  final double score;

  bool get isFood => type.toLowerCase() == 'food';

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    double numVal(dynamic v) => v is num ? v.toDouble() : 0;
    return RecommendationItem(
      id: (json['id'] ?? json['Id']).toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      type: (json['type'] ?? json['Type'] ?? 'Food').toString(),
      caloriesKcal: numVal(json['caloriesKcal'] ?? json['CaloriesKcal']),
      proteinG: numVal(json['proteinG'] ?? json['ProteinG']),
      estimatedPriceVnd: json['estimatedPriceVnd'] is int
          ? json['estimatedPriceVnd'] as int
          : (json['EstimatedPriceVnd'] is int ? json['EstimatedPriceVnd'] as int : 0),
      cookingTimeMin: json['cookingTimeMin'] is int
          ? json['cookingTimeMin'] as int
          : (json['CookingTimeMin'] is int ? json['CookingTimeMin'] as int : 0),
      score: numVal(json['score'] ?? json['Score']),
    );
  }
}

class DailyMenuPlan {
  DailyMenuPlan({
    required this.targetCalories,
    required this.totalCalories,
    required this.items,
  });

  final int targetCalories;
  final int totalCalories;
  final List<DailyMenuPlanItem> items;

  factory DailyMenuPlan.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'];
    return DailyMenuPlan(
      targetCalories: json['targetCalories'] is int
          ? json['targetCalories'] as int
          : (json['TargetCalories'] is int ? json['TargetCalories'] as int : 0),
      totalCalories: json['totalCalories'] is int
          ? json['totalCalories'] as int
          : (json['TotalCalories'] is int ? json['TotalCalories'] as int : 0),
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(DailyMenuPlanItem.fromJson)
              .toList()
          : [],
    );
  }
}

class DailyMenuPlanItem {
  DailyMenuPlanItem({
    required this.id,
    required this.name,
    required this.entityType,
    required this.targetCalories,
  });

  final String id;
  final String name;
  final String entityType;
  final int targetCalories;

  bool get isFood => entityType.toLowerCase() == 'food';

  factory DailyMenuPlanItem.fromJson(Map<String, dynamic> json) {
    return DailyMenuPlanItem(
      id: (json['id'] ?? json['Id']).toString(),
      name: (json['foodName'] ?? json['FoodName'] ?? json['recipeName'] ?? json['RecipeName'] ?? '')
          .toString(),
      entityType: (json['mealType'] ?? json['MealType'] ?? 'Food').toString(),
      targetCalories: json['targetCalories'] is int
          ? json['targetCalories'] as int
          : (json['TargetCalories'] is int ? json['TargetCalories'] as int : 0),
    );
  }
}

/// Bộ lọc tìm món trên tab Khám phá (§2.3).
class FoodSearchFilters {
  const FoodSearchFilters({
    this.minCalories,
    this.maxCalories,
    this.proteinLevel,
    this.maxPriceVnd,
    this.category,
  });

  final double? minCalories;
  final double? maxCalories;
  final String? proteinLevel;
  final int? maxPriceVnd;
  final String? category;

  bool get hasAny =>
      minCalories != null ||
      maxCalories != null ||
      proteinLevel != null ||
      maxPriceVnd != null ||
      (category != null && category!.trim().isNotEmpty);

  FoodSearchFilters copyWith({
    double? minCalories,
    double? maxCalories,
    String? proteinLevel,
    int? maxPriceVnd,
    String? category,
    bool clearMinCalories = false,
    bool clearMaxCalories = false,
    bool clearProteinLevel = false,
    bool clearMaxPriceVnd = false,
    bool clearCategory = false,
  }) {
    return FoodSearchFilters(
      minCalories: clearMinCalories ? null : (minCalories ?? this.minCalories),
      maxCalories: clearMaxCalories ? null : (maxCalories ?? this.maxCalories),
      proteinLevel: clearProteinLevel ? null : (proteinLevel ?? this.proteinLevel),
      maxPriceVnd: clearMaxPriceVnd ? null : (maxPriceVnd ?? this.maxPriceVnd),
      category: clearCategory ? null : (category ?? this.category),
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
    final nested = json['ingredient'] ?? json['Ingredient'];
    String name = (json['ingredientName'] ?? json['IngredientName'] ?? '').toString();
    if (name.isEmpty && nested is Map<String, dynamic>) {
      name = (nested['nameVi'] ?? nested['NameVi'] ?? nested['name'] ?? '').toString();
    }
    if (name.isEmpty) {
      name = (json['nameVi'] ?? json['NameVi'] ?? '').toString();
    }
    return RecipeIngredientItem(
      ingredientName: name.isEmpty ? 'Nguyên liệu' : name,
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
