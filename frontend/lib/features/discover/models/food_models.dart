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

  int get totalCalories => ingredients.fold(0, (sum, ing) => sum + (ing.caloriesKcal ?? 0).round());

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
    this.matchReason,
    this.matchScore,
  });

  final String id;
  final String name;
  final String type;
  final double caloriesKcal;
  final double proteinG;
  final int estimatedPriceVnd;
  final int cookingTimeMin;
  final double score;
  final String? matchReason;
  final String? matchScore;

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
      matchReason: json['matchReason']?.toString() ?? json['MatchReason']?.toString(),
      matchScore: json['matchScore']?.toString() ?? json['MatchScore']?.toString(),
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
    required this.mealType,
    this.foodId,
    this.recipeId,
    required this.sourceEntityType,
    required this.targetCalories,
  });

  final String id;
  final String name;
  final String mealType;
  final String? foodId;
  final String? recipeId;
  final String sourceEntityType;
  final int targetCalories;

  bool get isFood =>
      sourceEntityType.toLowerCase() == 'food' || (foodId != null && recipeId == null);

  factory DailyMenuPlanItem.fromJson(Map<String, dynamic> json) {
    final foodId = (json['foodId'] ?? json['FoodId'])?.toString();
    final recipeId = (json['recipeId'] ?? json['RecipeId'])?.toString();
    final source = (json['sourceEntityType'] ?? json['SourceEntityType'] ?? '').toString();
    final inferredSource = source.isNotEmpty
        ? source
        : (foodId != null ? 'Food' : recipeId != null ? 'Recipe' : 'Food');

    return DailyMenuPlanItem(
      id: (json['id'] ?? json['Id']).toString(),
      name: (json['foodName'] ?? json['FoodName'] ?? json['recipeName'] ?? json['RecipeName'] ?? '')
          .toString(),
      mealType: (json['mealType'] ?? json['MealType'] ?? 'snack').toString(),
      foodId: foodId,
      recipeId: recipeId,
      sourceEntityType: inferredSource,
      targetCalories: json['targetCalories'] is int
          ? json['targetCalories'] as int
          : (json['TargetCalories'] is int ? json['TargetCalories'] as int : 0),
    );
  }

  Map<String, dynamic> toPlanItemJson() {
    return {
      'mealType': mealType,
      if (foodId != null) 'foodId': foodId,
      if (recipeId != null) 'recipeId': recipeId,
      'targetCalories': targetCalories,
    };
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
    this.caloriesKcal,
    this.notes,
  });

  final String ingredientName;
  final double quantity;
  final String unit;
  final double? caloriesKcal;
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
    final c = json['caloriesKcal'] ?? json['CaloriesKcal'];
    return RecipeIngredientItem(
      ingredientName: name.isEmpty ? 'Nguyên liệu' : name,
      quantity: q is num ? q.toDouble() : 0,
      unit: (json['unit'] ?? json['Unit'] ?? '').toString(),
      caloriesKcal: c is num ? c.toDouble() : null,
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

// ============================================================================
// RECOMMENDATION MODELS (Extended)
// ============================================================================

enum GenerateType {
  general,
  safe,
  weeklyPlan,
  budgetAware,
}

extension GenerateTypeExtension on GenerateType {
  String get value {
    switch (this) {
      case GenerateType.general:
        return 'general';
      case GenerateType.safe:
        return 'safe';
      case GenerateType.weeklyPlan:
        return 'weeklyPlan';
      case GenerateType.budgetAware:
        return 'budgetAware';
    }
  }
}

/// Request for general recommendation generation.
class RecommendationGenerateRequest {
  RecommendationGenerateRequest({
    this.mealType,
    this.targetCalories,
    this.maxResults = 10,
    this.excludeUserAllergies = false,
  });

  final String? mealType;
  final int? targetCalories;
  final int maxResults;
  final bool excludeUserAllergies;

  Map<String, dynamic> toJson() => {
        if (mealType != null) 'MealType': mealType,
        if (targetCalories != null) 'TargetCalories': targetCalories,
        'MaxResults': maxResults,
        'ExcludeUserAllergies': excludeUserAllergies,
      };
}

/// Request for safe (allergy-aware) recommendation.
class SafeRecommendationRequest {
  SafeRecommendationRequest({
    this.mealType,
    this.targetCalories,
    this.maxResults = 10,
  });

  final String? mealType;
  final int? targetCalories;
  final int maxResults;

  Map<String, dynamic> toJson() => {
        if (mealType != null) 'MealType': mealType,
        if (targetCalories != null) 'TargetCalories': targetCalories,
        'MaxResults': maxResults,
      };
}

/// Request for weekly meal plan generation.
class WeeklyPlanRequest {
  WeeklyPlanRequest({
    required this.startDate,
    required this.endDate,
    this.dailyTargetCalories,
    this.excludeUserAllergies = false,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int? dailyTargetCalories;
  final bool excludeUserAllergies;

  Map<String, dynamic> toJson() => {
        'StartDate': startDate.toIso8601String().split('T').first,
        'EndDate': endDate.toIso8601String().split('T').first,
        if (dailyTargetCalories != null) 'DailyTargetCalories': dailyTargetCalories,
        'ExcludeUserAllergies': excludeUserAllergies,
      };
}

/// Request for budget-aware recommendation.
class BudgetAwareRequest {
  BudgetAwareRequest({
    this.mealType,
    this.maxBudgetVnd,
    this.targetCalories,
    this.maxResults = 10,
    this.excludeUserAllergies = false,
  });

  final String? mealType;
  final int? maxBudgetVnd;
  final int? targetCalories;
  final int maxResults;
  final bool excludeUserAllergies;

  Map<String, dynamic> toJson() => {
        if (mealType != null) 'MealType': mealType,
        if (maxBudgetVnd != null) 'MaxBudgetVnd': maxBudgetVnd,
        if (targetCalories != null) 'TargetCalories': targetCalories,
        'MaxResults': maxResults,
        'ExcludeUserAllergies': excludeUserAllergies,
      };
}

/// Request for previewing recommendation before saving.
class RecommendationPreviewRequest {
  RecommendationPreviewRequest({
    this.mealType,
    this.targetCalories,
    this.maxBudgetVnd,
    this.excludeUserAllergies = false,
    this.preferenceTags = const [],
  });

  final String? mealType;
  final int? targetCalories;
  final int? maxBudgetVnd;
  final bool excludeUserAllergies;
  final List<String> preferenceTags;

  Map<String, dynamic> toJson() => {
        if (mealType != null) 'MealType': mealType,
        if (targetCalories != null) 'TargetCalories': targetCalories,
        if (maxBudgetVnd != null) 'MaxBudgetVnd': maxBudgetVnd,
        'ExcludeUserAllergies': excludeUserAllergies,
        'PreferenceTags': preferenceTags,
      };
}

/// Response from recommendation generation.
class RecommendationGenerateResponse {
  RecommendationGenerateResponse({
    required this.id,
    required this.createdAt,
    required this.mealType,
    this.targetCalories,
    required this.items,
  });

  final String id;
  final DateTime createdAt;
  final String mealType;
  final int? targetCalories;
  final List<RecommendationItem> items;

  factory RecommendationGenerateResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? json['recommendations'] ?? json['Recommendations'];
    return RecommendationGenerateResponse(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['CreatedAt']?.toString() ??
                json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      mealType: (json['mealType'] ?? json['MealType'] ?? 'general').toString(),
      targetCalories: json['targetCalories'] is int
          ? json['targetCalories'] as int
          : (json['TargetCalories'] is int ? json['TargetCalories'] as int : null),
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(RecommendationItem.fromJson)
              .toList()
          : [],
    );
  }

  int get totalCalories => items.fold(0, (sum, item) => sum + item.caloriesKcal.round());
}

/// Weekly meal plan response.
class WeeklyPlanResponse {
  WeeklyPlanResponse({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.dailyTargetCalories,
    required this.days,
  });

  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int? dailyTargetCalories;
  final List<WeeklyPlanDay> days;

  factory WeeklyPlanResponse.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] ?? json['Days'] ?? json['weeklyPlan'] ?? json['WeeklyPlan'] ?? [];
    return WeeklyPlanResponse(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? json['StartDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? json['EndDate']?.toString() ?? '') ?? DateTime.now(),
      dailyTargetCalories: json['dailyTargetCalories'] is int
          ? json['dailyTargetCalories'] as int
          : (json['DailyTargetCalories'] is int ? json['DailyTargetCalories'] as int : null),
      days: rawDays is List
          ? rawDays.whereType<Map<String, dynamic>>().map(WeeklyPlanDay.fromJson).toList()
          : [],
    );
  }
}

/// Single day in weekly plan.
class WeeklyPlanDay {
  WeeklyPlanDay({
    required this.date,
    required this.dayName,
    required this.meals,
  });

  final DateTime date;
  final String dayName;
  final List<DailyMenuPlanItem> meals;

  factory WeeklyPlanDay.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'] ?? json['Meals'] ?? json['items'] ?? json['Items'] ?? [];
    return WeeklyPlanDay(
      date: DateTime.tryParse(json['date']?.toString() ?? json['Date']?.toString() ?? '') ?? DateTime.now(),
      dayName: (json['dayName'] ?? json['DayName'] ?? json['dayOfWeek'] ?? 'Day').toString(),
      meals: rawMeals is List
          ? rawMeals.whereType<Map<String, dynamic>>().map(DailyMenuPlanItem.fromJson).toList()
          : [],
    );
  }

  int get totalCalories => meals.fold(0, (sum, meal) => sum + meal.targetCalories);
}

/// Budget-aware recommendation response.
class BudgetAwareResponse {
  BudgetAwareResponse({
    required this.id,
    required this.maxBudgetVnd,
    required this.totalEstimatedCost,
    required this.items,
    this.savingsVnd,
  });

  final String id;
  final int maxBudgetVnd;
  final int totalEstimatedCost;
  final List<RecommendationItem> items;
  final int? savingsVnd;

  factory BudgetAwareResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? json['recommendations'] ?? json['Recommendations'] ?? [];
    return BudgetAwareResponse(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      maxBudgetVnd: json['maxBudgetVnd'] is int
          ? json['maxBudgetVnd'] as int
          : (json['MaxBudgetVnd'] is int ? json['MaxBudgetVnd'] as int : 0),
      totalEstimatedCost: json['totalEstimatedCost'] is int
          ? json['totalEstimatedCost'] as int
          : (json['TotalEstimatedCost'] is int ? json['TotalEstimatedCost'] as int : 0),
      items: rawItems is List
          ? rawItems.whereType<Map<String, dynamic>>().map(RecommendationItem.fromJson).toList()
          : [],
      savingsVnd: json['savingsVnd'] is int
          ? json['savingsVnd'] as int
          : (json['SavingsVnd'] is int ? json['SavingsVnd'] as int : null),
    );
  }

  bool get isWithinBudget => totalEstimatedCost <= maxBudgetVnd;
}

/// Recommendation history item.
class RecommendationHistoryItem {
  RecommendationHistoryItem({
    required this.id,
    required this.mealType,
    required this.createdAt,
    this.targetCalories,
    required this.itemCount,
    this.feedback,
  });

  final String id;
  final String mealType;
  final DateTime createdAt;
  final int? targetCalories;
  final int itemCount;
  final RecommendationFeedback? feedback;

  factory RecommendationHistoryItem.fromJson(Map<String, dynamic> json) {
    return RecommendationHistoryItem(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      mealType: (json['mealType'] ?? json['MealType'] ?? 'general').toString(),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? json['CreatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      targetCalories: json['targetCalories'] is int
          ? json['targetCalories'] as int
          : (json['TargetCalories'] is int ? json['TargetCalories'] as int : null),
      itemCount: json['itemCount'] is int
          ? json['itemCount'] as int
          : (json['ItemCount'] is int ? json['ItemCount'] as int : 0),
      feedback: json['feedback'] != null || json['Feedback'] != null
          ? RecommendationFeedback.fromJson(json['feedback'] ?? json['Feedback'])
          : null,
    );
  }
}

/// Recommendation detail (full info).
class RecommendationDetail {
  RecommendationDetail({
    required this.id,
    required this.mealType,
    required this.createdAt,
    this.targetCalories,
    required this.items,
    this.explanation,
    this.feedback,
  });

  final String id;
  final String mealType;
  final DateTime createdAt;
  final int? targetCalories;
  final List<RecommendationItem> items;
  final String? explanation;
  final RecommendationFeedback? feedback;

  factory RecommendationDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? json['recommendations'] ?? json['Recommendations'] ?? [];
    return RecommendationDetail(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      mealType: (json['mealType'] ?? json['MealType'] ?? 'general').toString(),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? json['CreatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      targetCalories: json['targetCalories'] is int
          ? json['targetCalories'] as int
          : (json['TargetCalories'] is int ? json['TargetCalories'] as int : null),
      items: rawItems is List
          ? rawItems.whereType<Map<String, dynamic>>().map(RecommendationItem.fromJson).toList()
          : [],
      explanation: json['explanation']?.toString() ?? json['Explanation']?.toString(),
      feedback: json['feedback'] != null || json['Feedback'] != null
          ? RecommendationFeedback.fromJson(json['feedback'] ?? json['Feedback'])
          : null,
    );
  }
}

/// User feedback for a recommendation.
class RecommendationFeedback {
  RecommendationFeedback({
    required this.id,
    required this.recommendationId,
    required this.isLiked,
    this.comment,
    this.submittedAt,
  });

  final String id;
  final String recommendationId;
  final bool isLiked;
  final String? comment;
  final DateTime? submittedAt;

  factory RecommendationFeedback.fromJson(Map<String, dynamic> json) {
    return RecommendationFeedback(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      recommendationId: (json['recommendationId'] ?? json['RecommendationId'] ?? '').toString(),
      isLiked: json['isLiked'] == true || json['IsLiked'] == true,
      comment: json['comment']?.toString() ?? json['Comment']?.toString(),
      submittedAt: DateTime.tryParse(
            json['submittedAt']?.toString() ?? json['SubmittedAt']?.toString() ?? '',
          ),
    );
  }

  Map<String, dynamic> toJson() => {
        'RecommendationId': recommendationId,
        'IsLiked': isLiked,
        if (comment != null) 'Comment': comment,
      };
}

/// Feedback summary by meal type.
class FeedbackSummary {
  FeedbackSummary({
    required this.breakdown,
    this.totalLiked = 0,
    this.totalDisliked = 0,
  });

  final Map<String, FeedbackCount> breakdown;
  final int totalLiked;
  final int totalDisliked;

  factory FeedbackSummary.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] ?? json['Breakdown'] ?? {};
    final map = <String, FeedbackCount>{};
    rawBreakdown.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        map[key.toString()] = FeedbackCount.fromJson(value);
      }
    });
    return FeedbackSummary(
      breakdown: map,
      totalLiked: json['totalLiked'] is int ? json['totalLiked'] as int : 0,
      totalDisliked: json['totalDisliked'] is int ? json['totalDisliked'] as int : 0,
    );
  }
}

/// Feedback count per meal type.
class FeedbackCount {
  FeedbackCount({this.liked = 0, this.disliked = 0});

  final int liked;
  final int disliked;

  factory FeedbackCount.fromJson(Map<String, dynamic> json) {
    return FeedbackCount(
      liked: json['liked'] is int ? json['liked'] as int : 0,
      disliked: json['disliked'] is int ? json['disliked'] as int : 0,
    );
  }

  int get total => liked + disliked;
  double get likedRatio => total > 0 ? liked / total : 0;
}

/// Recommendation score breakdown.
class RecommendationScore {
  RecommendationScore({
    required this.entityId,
    required this.overallScore,
    this.calorieScore,
    this.macroScore,
    this.budgetScore,
    this.allergyScore,
    this.preferenceScore,
  });

  final String entityId;
  final double overallScore;
  final double? calorieScore;
  final double? macroScore;
  final double? budgetScore;
  final double? allergyScore;
  final double? preferenceScore;

  factory RecommendationScore.fromJson(Map<String, dynamic> json) {
    double? numVal(dynamic v) => v is num ? v.toDouble() : null;
    return RecommendationScore(
      entityId: (json['entityId'] ?? json['EntityId'] ?? '').toString(),
      overallScore: numVal(json['overallScore'] ?? json['OverallScore']) ?? 0,
      calorieScore: numVal(json['calorieScore'] ?? json['CalorieScore']),
      macroScore: numVal(json['macroScore'] ?? json['MacroScore']),
      budgetScore: numVal(json['budgetScore'] ?? json['BudgetScore']),
      allergyScore: numVal(json['allergyScore'] ?? json['AllergyScore']),
      preferenceScore: numVal(json['preferenceScore'] ?? json['PreferenceScore']),
    );
  }
}

/// Smart cooking schedule.
class SmartScheduleResponse {
  SmartScheduleResponse({
    required this.schedules,
  });

  final List<CookingScheduleItem> schedules;

  factory SmartScheduleResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['schedules'] ?? json['Schedules'] ?? [];
    return SmartScheduleResponse(
      schedules: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(CookingScheduleItem.fromJson).toList()
          : [],
    );
  }
}

/// Single cooking schedule item.
class CookingScheduleItem {
  CookingScheduleItem({
    required this.mealType,
    required this.cookByTime,
    required this.startPrepTime,
    this.steps = const [],
  });

  final String mealType;
  final DateTime cookByTime;
  final DateTime startPrepTime;
  final List<CookingStep> steps;

  factory CookingScheduleItem.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] ?? json['Steps'] ?? [];
    return CookingScheduleItem(
      mealType: (json['mealType'] ?? json['MealType'] ?? '').toString(),
      cookByTime: DateTime.tryParse(
            json['cookByTime']?.toString() ?? json['CookByTime']?.toString() ?? '',
          ) ??
          DateTime.now(),
      startPrepTime: DateTime.tryParse(
            json['startPrepTime']?.toString() ?? json['StartPrepTime']?.toString() ?? '',
          ) ??
          DateTime.now(),
      steps: rawSteps is List
          ? rawSteps.whereType<Map<String, dynamic>>().map(CookingStep.fromJson).toList()
          : [],
    );
  }

  Duration get prepDuration => cookByTime.difference(startPrepTime);
}

/// Cooking step in schedule.
class CookingStep {
  CookingStep({
    required this.stepOrder,
    required this.description,
    required this.durationMin,
  });

  final int stepOrder;
  final String description;
  final int durationMin;

  factory CookingStep.fromJson(Map<String, dynamic> json) {
    return CookingStep(
      stepOrder: json['stepOrder'] is int ? json['stepOrder'] as int : 0,
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      durationMin: json['durationMin'] is int
          ? json['durationMin'] as int
          : (json['DurationMin'] is int ? json['DurationMin'] as int : 0),
    );
  }
}
