import 'dart:convert';

class _RecommendationJson {
  const _RecommendationJson._();

  static dynamic value(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final candidate = json[key];
      if (candidate != null) return candidate;
    }
    return null;
  }

  static Map<String, dynamic> map(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return map(jsonDecode(raw));
      } on FormatException {
        return const {};
      }
    }
    return const {};
  }

  static List<Map<String, dynamic>> maps(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map(map).where((item) => item.isNotEmpty).toList();
  }

  static String? text(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? null : value;
    }
    if (raw is List) {
      final value = raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .join('\n');
      return value.isEmpty ? null : value;
    }
    return raw.toString();
  }

  static double number(dynamic raw, {double fallback = 0}) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static int integer(dynamic raw, {int fallback = 0}) {
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static int? nullableInteger(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.round();
    return int.tryParse(raw.toString());
  }

  static double score(dynamic raw) {
    final value = number(raw);
    return value > 1 && value <= 100 ? value / 100 : value;
  }

  static bool? boolean(dynamic raw) {
    if (raw is bool) return raw;
    final value = raw?.toString().trim().toLowerCase();
    if (value == 'true' || value == '1') return true;
    if (value == 'false' || value == '0') return false;
    return null;
  }

  static List<String> strings(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((item) => text(item)).whereType<String>().toList();
  }

  static DateTime date(dynamic raw, {DateTime? fallback}) {
    return DateTime.tryParse(raw?.toString() ?? '') ??
        fallback ??
        DateTime.now();
  }

  static Map<String, dynamic> response(Map<String, dynamic> json) {
    final wrapped = map(
      value(json, const ['data', 'Data', 'result', 'Result']),
    );
    return wrapped.isEmpty ? json : {...json, ...wrapped};
  }
}

class FoodItem {
  FoodItem({
    required this.id,
    required this.nameVi,
    this.nameEn,
    this.category,
    this.description,
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.estimatedPriceVnd,
    this.defaultServingG,
    this.imageUrl,
    this.region,
    this.isActive,
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
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final int? estimatedPriceVnd;
  final int? defaultServingG;
  final String? imageUrl;
  final String? region;
  final bool? isActive;
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
      description:
          json['description']?.toString() ?? json['Description']?.toString(),
      caloriesKcal: _num(
        json['caloriesKcal'] ?? json['CaloriesKcal'] ?? json['calories_kcal'],
      ),
      proteinG: _num(json['proteinG'] ?? json['ProteinG'] ?? json['protein_g']),
      carbsG: _num(json['carbsG'] ?? json['CarbsG'] ?? json['carbs_g']),
      fatG: _num(json['fatG'] ?? json['FatG'] ?? json['fat_g']),
      fiberG: _num(json['fiberG'] ?? json['FiberG'] ?? json['fiber_g']),
      estimatedPriceVnd: _RecommendationJson.nullableInteger(
        json['estimatedPriceVnd'] ??
            json['EstimatedPriceVnd'] ??
            json['estimated_price_vnd'],
      ),
      defaultServingG: _RecommendationJson.nullableInteger(
        json['defaultServingG'] ??
            json['DefaultServingG'] ??
            json['default_serving_g'],
      ),
      imageUrl: _RecommendationJson.text(
        json['imageUrl'] ?? json['ImageUrl'] ?? json['image_url'],
      ),
      region: _RecommendationJson.text(json['region'] ?? json['Region']),
      isActive: _RecommendationJson.boolean(
        json['isActive'] ?? json['IsActive'] ?? json['is_active'],
      ),
      allergenLabelsVi: listOf(
        json['allergenLabelsVi'] ??
            json['AllergenLabelsVi'] ??
            json['allergen_labels_vi'],
      ),
      matchedAllergens: listOf(
        json['matchedAllergens'] ??
            json['MatchedAllergens'] ??
            json['matched_allergens'],
      ),
      allergyRiskLevel:
          (json['allergyRiskLevel'] ??
                  json['AllergyRiskLevel'] ??
                  json['allergy_risk_level'] ??
                  'none')
              .toString(),
      isSafeForUser:
          (json['isSafeForUser'] ??
              json['IsSafeForUser'] ??
              json['is_safe_for_user']) !=
          false,
    );
  }
}

class RecipeItem {
  RecipeItem({
    required this.id,
    required this.title,
    this.description,
    this.prepTimeMin,
    this.cookTimeMin,
    this.totalTimeMin,
    this.servings,
    this.difficulty,
    this.mealType,
    this.estimatedPriceVnd,
    this.instructions,
    this.imageUrl,
    this.videoUrl,
    this.isActive,
    this.foodId,
    this.ingredients = const [],
    this.matchedAllergens = const [],
    this.allergyRiskLevel = 'none',
    this.isSafeForUser = true,
  });

  final String id;
  final String title;
  final String? description;
  final int? prepTimeMin;
  final int? cookTimeMin;
  final int? totalTimeMin;
  final int? servings;
  final String? difficulty;
  final String? mealType;
  final int? estimatedPriceVnd;
  final String? instructions;
  final String? imageUrl;
  final String? videoUrl;
  final bool? isActive;
  final String? foodId;
  final List<RecipeIngredientItem> ingredients;
  final List<String> matchedAllergens;
  final String allergyRiskLevel;
  final bool isSafeForUser;

  int get totalCalories =>
      ingredients.fold(0, (sum, ing) => sum + (ing.caloriesKcal ?? 0).round());

  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] ?? json['Ingredients'];
    List<String> listOf(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return RecipeItem(
      id: _RecommendationJson.text(json['id'] ?? json['Id']) ?? '',
      title: _RecommendationJson.text(json['title'] ?? json['Title']) ?? '',
      description: _RecommendationJson.text(
        json['description'] ?? json['Description'],
      ),
      prepTimeMin: _RecommendationJson.nullableInteger(
        json['prepTimeMin'] ?? json['PrepTimeMin'] ?? json['prep_time_min'],
      ),
      cookTimeMin: _RecommendationJson.nullableInteger(
        json['cookTimeMin'] ?? json['CookTimeMin'] ?? json['cook_time_min'],
      ),
      totalTimeMin: _RecommendationJson.nullableInteger(
        json['totalTimeMin'] ?? json['TotalTimeMin'] ?? json['total_time_min'],
      ),
      servings: _RecommendationJson.nullableInteger(
        json['servings'] ?? json['Servings'],
      ),
      difficulty: _RecommendationJson.text(
        json['difficulty'] ?? json['Difficulty'],
      ),
      mealType: _RecommendationJson.text(
        json['mealType'] ?? json['MealType'] ?? json['meal_type'],
      ),
      estimatedPriceVnd: _RecommendationJson.nullableInteger(
        json['estimatedPriceVnd'] ??
            json['EstimatedPriceVnd'] ??
            json['estimated_price_vnd'],
      ),
      instructions: _RecommendationJson.text(
        json['instructions'] ?? json['Instructions'],
      ),
      imageUrl: _RecommendationJson.text(
        json['imageUrl'] ?? json['ImageUrl'] ?? json['image_url'],
      ),
      videoUrl: _RecommendationJson.text(
        json['videoUrl'] ?? json['VideoUrl'] ?? json['video_url'],
      ),
      isActive: _RecommendationJson.boolean(
        json['isActive'] ?? json['IsActive'] ?? json['is_active'],
      ),
      foodId: _RecommendationJson.text(
        json['foodId'] ?? json['FoodId'] ?? json['food_id'],
      ),
      ingredients: rawIngredients is List
          ? rawIngredients
                .whereType<Map<String, dynamic>>()
                .map(RecipeIngredientItem.fromJson)
                .toList()
          : [],
      matchedAllergens: listOf(
        json['matchedAllergens'] ??
            json['MatchedAllergens'] ??
            json['matched_allergens'],
      ),
      allergyRiskLevel:
          (json['allergyRiskLevel'] ??
                  json['AllergyRiskLevel'] ??
                  json['allergy_risk_level'] ??
                  'none')
              .toString(),
      isSafeForUser:
          (json['isSafeForUser'] ??
              json['IsSafeForUser'] ??
              json['is_safe_for_user']) !=
          false,
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
      unitDefault:
          json['unitDefault']?.toString() ?? json['UnitDefault']?.toString(),
      matchedAllergens: listOf(
        json['matchedAllergens'] ?? json['MatchedAllergens'],
      ),
      allergyRiskLevel:
          (json['allergyRiskLevel'] ?? json['AllergyRiskLevel'] ?? 'none')
              .toString(),
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
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.mealType,
    this.description,
    this.instructions,
    this.imageUrl,
    this.videoUrl,
    this.prepTimeMin,
    this.totalTimeMin,
    this.servings,
    this.difficulty,
    this.allergenLabelsVi = const [],
    this.matchedAllergens = const [],
    this.allergyRiskLevel = 'none',
    this.isSafeForUser = true,
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
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String? mealType;
  final String? description;
  final String? instructions;
  final String? imageUrl;
  final String? videoUrl;
  final int? prepTimeMin;
  final int? totalTimeMin;
  final int? servings;
  final String? difficulty;
  final List<String> allergenLabelsVi;
  final List<String> matchedAllergens;
  final String allergyRiskLevel;
  final bool isSafeForUser;
  final String? matchReason;
  final String? matchScore;

  bool get isFood => type.toLowerCase() == 'food';
  bool get hasAllergyWarning => matchedAllergens.isNotEmpty || !isSafeForUser;
  int get displayTimeMin => totalTimeMin ?? cookingTimeMin + (prepTimeMin ?? 0);

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    final nested = _RecommendationJson.map(
      _RecommendationJson.value(json, const [
        'food',
        'Food',
        'recipe',
        'Recipe',
        'item',
        'Item',
      ]),
    );
    final data = {...nested, ...json};
    final isFood = _RecommendationJson.boolean(
      _RecommendationJson.value(data, const ['is_food', 'isFood', 'IsFood']),
    );
    final explicitType = _RecommendationJson.text(
      _RecommendationJson.value(data, const [
        'type',
        'Type',
        'source_entity_type',
        'sourceEntityType',
      ]),
    );
    final type = explicitType ?? (isFood == false ? 'Recipe' : 'Food');

    return RecommendationItem(
      id:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'id',
              'Id',
              'food_id',
              'foodId',
              'FoodId',
              'recipe_id',
              'recipeId',
              'RecipeId',
            ]),
          ) ??
          '',
      name:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'name',
              'Name',
              'title',
              'Title',
              'name_vi',
              'nameVi',
              'NameVi',
            ]),
          ) ??
          '',
      type: type,
      caloriesKcal: _RecommendationJson.number(
        _RecommendationJson.value(data, const [
          'calories_kcal',
          'caloriesKcal',
          'CaloriesKcal',
        ]),
      ),
      proteinG: _RecommendationJson.number(
        _RecommendationJson.value(data, const [
          'protein_g',
          'proteinG',
          'ProteinG',
        ]),
      ),
      carbsG: _RecommendationJson.number(
        _RecommendationJson.value(data, const ['carbs_g', 'carbsG', 'CarbsG']),
      ),
      fatG: _RecommendationJson.number(
        _RecommendationJson.value(data, const ['fat_g', 'fatG', 'FatG']),
      ),
      fiberG: _RecommendationJson.number(
        _RecommendationJson.value(data, const ['fiber_g', 'fiberG', 'FiberG']),
      ),
      estimatedPriceVnd: _RecommendationJson.integer(
        _RecommendationJson.value(data, const [
          'estimated_price_vnd',
          'estimatedPriceVnd',
          'EstimatedPriceVnd',
          'price_vnd',
          'priceVnd',
        ]),
      ),
      cookingTimeMin: _RecommendationJson.integer(
        _RecommendationJson.value(data, const [
          'cooking_time_min',
          'cookingTimeMin',
          'CookingTimeMin',
          'cook_time_min',
          'cookTimeMin',
        ]),
      ),
      prepTimeMin: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'prep_time_min',
          'prepTimeMin',
          'PrepTimeMin',
        ]),
      ),
      totalTimeMin: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'total_time_min',
          'totalTimeMin',
          'TotalTimeMin',
        ]),
      ),
      servings: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const ['servings', 'Servings']),
      ),
      score: _RecommendationJson.score(
        _RecommendationJson.value(data, const [
          'score',
          'Score',
          'confidence',
          'Confidence',
        ]),
      ),
      mealType: _RecommendationJson.text(
        _RecommendationJson.value(data, const [
          'meal_slot',
          'mealSlot',
          'meal_type',
          'mealType',
          'MealType',
        ]),
      ),
      description: _RecommendationJson.text(
        _RecommendationJson.value(data, const ['description', 'Description']),
      ),
      instructions: _RecommendationJson.text(
        _RecommendationJson.value(data, const ['instructions', 'Instructions']),
      ),
      imageUrl: _RecommendationJson.text(
        _RecommendationJson.value(data, const [
          'image_url',
          'imageUrl',
          'ImageUrl',
        ]),
      ),
      videoUrl: _RecommendationJson.text(
        _RecommendationJson.value(data, const [
          'video_url',
          'videoUrl',
          'VideoUrl',
        ]),
      ),
      difficulty: _RecommendationJson.text(
        _RecommendationJson.value(data, const ['difficulty', 'Difficulty']),
      ),
      allergenLabelsVi: _RecommendationJson.strings(
        _RecommendationJson.value(data, const [
          'allergen_labels_vi',
          'allergenLabelsVi',
          'AllergenLabelsVi',
        ]),
      ),
      matchedAllergens: _RecommendationJson.strings(
        _RecommendationJson.value(data, const [
          'matched_allergens',
          'matchedAllergens',
          'MatchedAllergens',
        ]),
      ),
      allergyRiskLevel:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'allergy_risk_level',
              'allergyRiskLevel',
              'AllergyRiskLevel',
            ]),
          ) ??
          'none',
      isSafeForUser:
          _RecommendationJson.boolean(
            _RecommendationJson.value(data, const [
              'is_safe_for_user',
              'isSafeForUser',
              'IsSafeForUser',
            ]),
          ) ??
          true,
      matchReason: _RecommendationJson.text(
        _RecommendationJson.value(data, const [
          'match_reason',
          'matchReason',
          'MatchReason',
        ]),
      ),
      matchScore: _RecommendationJson.text(
        _RecommendationJson.value(data, const [
          'match_score',
          'matchScore',
          'MatchScore',
        ]),
      ),
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
    this.recommendation,
  });

  final String id;
  final String name;
  final String mealType;
  final String? foodId;
  final String? recipeId;
  final String sourceEntityType;
  final int targetCalories;
  final RecommendationItem? recommendation;

  bool get isFood =>
      sourceEntityType.toLowerCase() == 'food' ||
      (foodId != null && recipeId == null);

  factory DailyMenuPlanItem.fromJson(Map<String, dynamic> json) {
    final foodId = _RecommendationJson.text(
      _RecommendationJson.value(json, const ['food_id', 'foodId', 'FoodId']),
    );
    final recipeId = _RecommendationJson.text(
      _RecommendationJson.value(json, const [
        'recipe_id',
        'recipeId',
        'RecipeId',
      ]),
    );
    final recommendation = RecommendationItem.fromJson(json);
    final source =
        _RecommendationJson.text(
          _RecommendationJson.value(json, const [
            'source_entity_type',
            'sourceEntityType',
            'SourceEntityType',
            'type',
            'Type',
          ]),
        ) ??
        '';
    final inferredSource = source.isNotEmpty
        ? source
        : (foodId != null
              ? 'Food'
              : recipeId != null
              ? 'Recipe'
              : recommendation.type);

    return DailyMenuPlanItem(
      id: recommendation.id,
      name:
          _RecommendationJson.text(
            _RecommendationJson.value(json, const [
              'food_name',
              'foodName',
              'FoodName',
              'recipe_name',
              'recipeName',
              'RecipeName',
            ]),
          ) ??
          recommendation.name,
      mealType:
          _RecommendationJson.text(
            _RecommendationJson.value(json, const [
              'meal_slot',
              'mealSlot',
              'meal_type',
              'mealType',
              'MealType',
            ]),
          ) ??
          'snack',
      foodId: foodId,
      recipeId: recipeId,
      sourceEntityType: inferredSource,
      targetCalories:
          _RecommendationJson.nullableInteger(
            _RecommendationJson.value(json, const [
              'target_calories',
              'targetCalories',
              'TargetCalories',
              'calories_kcal',
              'caloriesKcal',
              'CaloriesKcal',
            ]),
          ) ??
          recommendation.caloriesKcal.round(),
      recommendation: recommendation.name.isEmpty ? null : recommendation,
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
      proteinLevel: clearProteinLevel
          ? null
          : (proteinLevel ?? this.proteinLevel),
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
    String name = (json['ingredientName'] ?? json['IngredientName'] ?? '')
        .toString();
    if (name.isEmpty && nested is Map<String, dynamic>) {
      name = (nested['nameVi'] ?? nested['NameVi'] ?? nested['name'] ?? '')
          .toString();
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
    this.nameEn,
    this.category,
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.estimatedPriceVnd,
    this.imageUrl,
    this.createdAt,
  });

  final String foodId;
  final String nameVi;
  final String? nameEn;
  final String? category;
  final double? caloriesKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final int? estimatedPriceVnd;
  final String? imageUrl;
  final DateTime? createdAt;

  factory FavoriteFoodItem.fromFood(FoodItem food) {
    return FavoriteFoodItem(
      foodId: food.id,
      nameVi: food.nameVi,
      nameEn: food.nameEn,
      category: food.category,
      caloriesKcal: food.caloriesKcal,
      proteinG: food.proteinG,
      carbsG: food.carbsG,
      fatG: food.fatG,
      estimatedPriceVnd: food.estimatedPriceVnd,
      imageUrl: food.imageUrl,
    );
  }

  factory FavoriteFoodItem.fromRecommendation(RecommendationItem item) {
    return FavoriteFoodItem(
      foodId: item.id,
      nameVi: item.name,
      caloriesKcal: item.caloriesKcal,
      proteinG: item.proteinG,
      carbsG: item.carbsG,
      fatG: item.fatG,
      estimatedPriceVnd: item.estimatedPriceVnd,
      imageUrl: item.imageUrl,
    );
  }

  factory FavoriteFoodItem.fromJson(Map<String, dynamic> json) {
    final c = json['caloriesKcal'] ?? json['CaloriesKcal'];
    return FavoriteFoodItem(
      foodId: (json['foodId'] ?? json['FoodId']).toString(),
      nameVi: (json['nameVi'] ?? json['NameVi'] ?? '').toString(),
      nameEn: json['nameEn']?.toString() ?? json['NameEn']?.toString(),
      category: json['category']?.toString() ?? json['Category']?.toString(),
      caloriesKcal: c is num ? c.toDouble() : null,
      proteinG: _RecommendationJson.number(
        json['proteinG'] ?? json['ProteinG'],
      ),
      carbsG: _RecommendationJson.number(json['carbsG'] ?? json['CarbsG']),
      fatG: _RecommendationJson.number(json['fatG'] ?? json['FatG']),
      estimatedPriceVnd: _RecommendationJson.nullableInteger(
        json['estimatedPriceVnd'] ?? json['EstimatedPriceVnd'],
      ),
      imageUrl: json['imageUrl']?.toString() ?? json['ImageUrl']?.toString(),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'nameVi': nameVi,
      if (nameEn != null) 'nameEn': nameEn,
      if (category != null) 'category': category,
      if (caloriesKcal != null) 'caloriesKcal': caloriesKcal,
      if (proteinG != null) 'proteinG': proteinG,
      if (carbsG != null) 'carbsG': carbsG,
      if (fatG != null) 'fatG': fatG,
      if (estimatedPriceVnd != null) 'estimatedPriceVnd': estimatedPriceVnd,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

// ============================================================================
// RECOMMENDATION MODELS (Extended)
// ============================================================================

enum GenerateType { general, safe, weeklyPlan, budgetAware }

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
    this.totalCaloriesFromApi,
    this.totalEstimatedCost,
    this.maxBudgetVnd,
    this.mode,
    required this.items,
  });

  final String id;
  final DateTime createdAt;
  final String mealType;
  final int? targetCalories;
  final int? totalCaloriesFromApi;
  final int? totalEstimatedCost;
  final int? maxBudgetVnd;
  final String? mode;
  final List<RecommendationItem> items;

  factory RecommendationGenerateResponse.fromJson(Map<String, dynamic> json) {
    final data = _RecommendationJson.response(json);
    final rawItems = _RecommendationJson.value(data, const [
      'items',
      'Items',
      'recommendations',
      'Recommendations',
    ]);
    return RecommendationGenerateResponse(
      id:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'id',
              'Id',
              'request_id',
              'requestId',
            ]),
          ) ??
          '',
      createdAt: _RecommendationJson.date(
        _RecommendationJson.value(data, const [
          'created_at',
          'createdAt',
          'CreatedAt',
          'generated_at',
          'generatedAt',
        ]),
      ),
      mealType:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'meal_slot',
              'mealSlot',
              'meal_type',
              'mealType',
              'MealType',
            ]),
          ) ??
          'general',
      targetCalories: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'target_calories',
          'targetCalories',
          'TargetCalories',
        ]),
      ),
      totalCaloriesFromApi: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'total_calories',
          'totalCalories',
          'TotalCalories',
        ]),
      ),
      totalEstimatedCost: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'total_estimated_cost',
          'totalEstimatedCost',
          'TotalEstimatedCost',
        ]),
      ),
      maxBudgetVnd: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'max_budget_vnd',
          'maxBudgetVnd',
          'MaxBudgetVnd',
          'budget_vnd',
          'budgetVnd',
        ]),
      ),
      mode: _RecommendationJson.text(
        _RecommendationJson.value(data, const ['mode', 'Mode', 'type', 'Type']),
      ),
      items: _RecommendationJson.maps(
        rawItems,
      ).map(RecommendationItem.fromJson).toList(),
    );
  }

  int get totalCalories =>
      totalCaloriesFromApi ??
      items.fold(0, (sum, item) => sum + item.caloriesKcal.round());
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
    final data = _RecommendationJson.response(json);
    final rawDays = _RecommendationJson.value(data, const [
      'days',
      'Days',
      'weekly_plan',
      'weeklyPlan',
      'WeeklyPlan',
      'plan',
      'Plan',
    ]);
    final days = _RecommendationJson.maps(
      rawDays,
    ).map(WeeklyPlanDay.fromJson).toList();
    return WeeklyPlanResponse(
      id:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'id',
              'Id',
              'request_id',
              'requestId',
            ]),
          ) ??
          '',
      startDate: _RecommendationJson.date(
        _RecommendationJson.value(data, const [
          'start_date',
          'startDate',
          'StartDate',
          'date',
          'Date',
        ]),
      ),
      endDate: _RecommendationJson.date(
        _RecommendationJson.value(data, const [
          'end_date',
          'endDate',
          'EndDate',
        ]),
      ),
      dailyTargetCalories: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'daily_target_calories',
          'dailyTargetCalories',
          'DailyTargetCalories',
          'target_calories',
          'targetCalories',
        ]),
      ),
      days: days,
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
    final rawMeals = _RecommendationJson.value(json, const [
      'meals',
      'Meals',
      'items',
      'Items',
      'recommendations',
      'Recommendations',
    ]);
    return WeeklyPlanDay(
      date: _RecommendationJson.date(
        _RecommendationJson.value(json, const [
          'date',
          'Date',
          'plan_date',
          'planDate',
        ]),
      ),
      dayName:
          _RecommendationJson.text(
            _RecommendationJson.value(json, const [
              'day_name',
              'dayName',
              'DayName',
              'day_of_week',
              'dayOfWeek',
            ]),
          ) ??
          'Day',
      meals: _RecommendationJson.maps(
        rawMeals,
      ).map(DailyMenuPlanItem.fromJson).toList(),
    );
  }

  int get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.targetCalories);
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
    final data = _RecommendationJson.response(json);
    final rawItems = _RecommendationJson.value(data, const [
      'items',
      'Items',
      'recommendations',
      'Recommendations',
    ]);
    final items = _RecommendationJson.maps(
      rawItems,
    ).map(RecommendationItem.fromJson).toList();
    return BudgetAwareResponse(
      id:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'id',
              'Id',
              'request_id',
              'requestId',
            ]),
          ) ??
          '',
      maxBudgetVnd: _RecommendationJson.integer(
        _RecommendationJson.value(data, const [
          'max_budget_vnd',
          'maxBudgetVnd',
          'MaxBudgetVnd',
          'budget_vnd',
          'budgetVnd',
        ]),
      ),
      totalEstimatedCost:
          _RecommendationJson.nullableInteger(
            _RecommendationJson.value(data, const [
              'total_estimated_cost',
              'totalEstimatedCost',
              'TotalEstimatedCost',
            ]),
          ) ??
          items.fold(0, (total, item) => total + item.estimatedPriceVnd),
      items: items,
      savingsVnd: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'savings_vnd',
          'savingsVnd',
          'SavingsVnd',
        ]),
      ),
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
    this.type,
    this.summary,
    this.confidence,
    this.feedback,
  });

  final String id;
  final String mealType;
  final DateTime createdAt;
  final int? targetCalories;
  final int itemCount;
  final String? type;
  final String? summary;
  final double? confidence;
  final RecommendationFeedback? feedback;

  factory RecommendationHistoryItem.fromJson(Map<String, dynamic> json) {
    final summary = _RecommendationJson.text(
      _RecommendationJson.value(json, const ['summary', 'Summary']),
    );
    final payload = _RecommendationJson.map(summary);
    final data = {...json, ...payload};
    final type = _RecommendationJson.text(
      _RecommendationJson.value(json, const ['type', 'Type']),
    );
    final rawItems = _RecommendationJson.value(data, const [
      'items',
      'Items',
      'recommendations',
      'Recommendations',
    ]);
    final mealType =
        _RecommendationJson.text(
          _RecommendationJson.value(data, const [
            'meal_slot',
            'mealSlot',
            'meal_type',
            'mealType',
            'MealType',
          ]),
        ) ??
        _mealTypeFromHistoryType(type);

    return RecommendationHistoryItem(
      id:
          _RecommendationJson.text(
            _RecommendationJson.value(json, const ['id', 'Id']),
          ) ??
          '',
      mealType: mealType,
      createdAt: _RecommendationJson.date(
        _RecommendationJson.value(json, const [
          'created_at',
          'createdAt',
          'CreatedAt',
        ]),
      ),
      targetCalories: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'target_calories',
          'targetCalories',
          'TargetCalories',
        ]),
      ),
      itemCount:
          _RecommendationJson.nullableInteger(
            _RecommendationJson.value(data, const [
              'item_count',
              'itemCount',
              'ItemCount',
            ]),
          ) ??
          _RecommendationJson.maps(rawItems).length,
      type: type,
      summary: summary,
      confidence:
          _RecommendationJson.number(
            _RecommendationJson.value(json, const ['confidence', 'Confidence']),
            fallback: double.nan,
          ).isNaN
          ? null
          : _RecommendationJson.number(
              _RecommendationJson.value(json, const [
                'confidence',
                'Confidence',
              ]),
            ),
      feedback: json['feedback'] != null || json['Feedback'] != null
          ? RecommendationFeedback.fromJson(
              json['feedback'] ?? json['Feedback'],
            )
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
    this.type,
    this.input,
    this.output,
    this.confidence,
    this.explanation,
    this.feedback,
  });

  final String id;
  final String mealType;
  final DateTime createdAt;
  final int? targetCalories;
  final List<RecommendationItem> items;
  final String? type;
  final String? input;
  final String? output;
  final double? confidence;
  final String? explanation;
  final RecommendationFeedback? feedback;

  factory RecommendationDetail.fromJson(Map<String, dynamic> json) {
    final input = _RecommendationJson.text(
      _RecommendationJson.value(json, const ['input', 'Input']),
    );
    final output = _RecommendationJson.text(
      _RecommendationJson.value(json, const ['output', 'Output']),
    );
    final inputData = _RecommendationJson.map(input);
    final outputData = _RecommendationJson.map(output);
    final data = {...json, ...inputData, ...outputData};
    final rawItems = _RecommendationJson.value(data, const [
      'items',
      'Items',
      'recommendations',
      'Recommendations',
    ]);
    final confidenceRaw = _RecommendationJson.value(json, const [
      'confidence',
      'Confidence',
    ]);
    final confidence = confidenceRaw == null
        ? null
        : _RecommendationJson.number(confidenceRaw);

    return RecommendationDetail(
      id:
          _RecommendationJson.text(
            _RecommendationJson.value(json, const ['id', 'Id']),
          ) ??
          '',
      mealType:
          _RecommendationJson.text(
            _RecommendationJson.value(data, const [
              'meal_slot',
              'mealSlot',
              'meal_type',
              'mealType',
              'MealType',
            ]),
          ) ??
          _mealTypeFromHistoryType(
            _RecommendationJson.text(
              _RecommendationJson.value(json, const ['type', 'Type']),
            ),
          ),
      createdAt: _RecommendationJson.date(
        _RecommendationJson.value(json, const [
          'created_at',
          'createdAt',
          'CreatedAt',
        ]),
      ),
      targetCalories: _RecommendationJson.nullableInteger(
        _RecommendationJson.value(data, const [
          'target_calories',
          'targetCalories',
          'TargetCalories',
        ]),
      ),
      items: _RecommendationJson.maps(
        rawItems,
      ).map(RecommendationItem.fromJson).toList(),
      type: _RecommendationJson.text(
        _RecommendationJson.value(json, const ['type', 'Type']),
      ),
      input: input,
      output: output,
      confidence: confidence,
      explanation: _RecommendationJson.text(
        _RecommendationJson.value(data, const ['explanation', 'Explanation']),
      ),
      feedback: json['feedback'] != null || json['Feedback'] != null
          ? RecommendationFeedback.fromJson(
              json['feedback'] ?? json['Feedback'],
            )
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
    final rating = _RecommendationJson.nullableInteger(
      _RecommendationJson.value(json, const ['rating', 'Rating']),
    );
    return RecommendationFeedback(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      recommendationId:
          (json['recommendationId'] ?? json['RecommendationId'] ?? '')
              .toString(),
      isLiked:
          _RecommendationJson.boolean(
            _RecommendationJson.value(json, const [
              'isLiked',
              'IsLiked',
              'wouldRecommend',
              'WouldRecommend',
            ]),
          ) ??
          (rating == null || rating >= 3),
      comment: _RecommendationJson.text(
        _RecommendationJson.value(json, const [
          'feedback',
          'Feedback',
          'comment',
          'Comment',
        ]),
      ),
      submittedAt: DateTime.tryParse(
        json['submittedAt']?.toString() ??
            json['SubmittedAt']?.toString() ??
            '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'RecommendationId': recommendationId,
    'Rating': isLiked ? 5 : 1,
    if (comment != null) 'Feedback': comment,
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
    final rawBreakdown =
        json['breakdown'] ??
        json['Breakdown'] ??
        json['byMealType'] ??
        json['ByMealType'] ??
        {};
    final map = <String, FeedbackCount>{};
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((key, value) {
        if (value is Map) {
          map[key.toString()] = FeedbackCount.fromJson(
            value.map(
              (entryKey, entryValue) =>
                  MapEntry(entryKey.toString(), entryValue),
            ),
          );
        }
      });
    }
    return FeedbackSummary(
      breakdown: map,
      totalLiked: _RecommendationJson.integer(
        json['totalLiked'] ??
            json['TotalLiked'] ??
            json['positiveCount'] ??
            json['PositiveCount'],
      ),
      totalDisliked: _RecommendationJson.integer(
        json['totalDisliked'] ??
            json['TotalDisliked'] ??
            json['negativeCount'] ??
            json['NegativeCount'],
      ),
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
      liked: _RecommendationJson.integer(
        json['liked'] ?? json['Liked'] ?? json['positive'] ?? json['Positive'],
      ),
      disliked: _RecommendationJson.integer(
        json['disliked'] ??
            json['Disliked'] ??
            json['negative'] ??
            json['Negative'],
      ),
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
    double? numVal(dynamic v) {
      if (v == null) return null;
      final value = _RecommendationJson.number(v, fallback: double.nan);
      if (value.isNaN) return null;
      return value > 1 ? value / 100 : value;
    }

    return RecommendationScore(
      entityId: (json['entityId'] ?? json['EntityId'] ?? '').toString(),
      overallScore: numVal(json['overallScore'] ?? json['OverallScore']) ?? 0,
      calorieScore: numVal(
        json['calorieScore'] ?? json['CaloriesScore'] ?? json['CalorieScore'],
      ),
      macroScore: numVal(json['macroScore'] ?? json['MacroScore']),
      budgetScore: numVal(json['budgetScore'] ?? json['BudgetScore']),
      allergyScore: numVal(json['allergyScore'] ?? json['AllergyScore']),
      preferenceScore: numVal(
        json['preferenceScore'] ?? json['PreferenceScore'],
      ),
    );
  }
}

String _mealTypeFromHistoryType(String? type) {
  final normalized = type?.toLowerCase() ?? '';
  if (normalized.contains('breakfast')) return 'breakfast';
  if (normalized.contains('lunch')) return 'lunch';
  if (normalized.contains('dinner')) return 'dinner';
  if (normalized.contains('snack')) return 'snack';
  return 'general';
}

/// Smart cooking schedule.
class SmartScheduleResponse {
  SmartScheduleResponse({required this.schedules});

  final List<CookingScheduleItem> schedules;

  factory SmartScheduleResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['schedules'] ?? json['Schedules'] ?? [];
    return SmartScheduleResponse(
      schedules: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(CookingScheduleItem.fromJson)
                .toList()
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
      cookByTime:
          DateTime.tryParse(
            json['cookByTime']?.toString() ??
                json['CookByTime']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      startPrepTime:
          DateTime.tryParse(
            json['startPrepTime']?.toString() ??
                json['StartPrepTime']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      steps: rawSteps is List
          ? rawSteps
                .whereType<Map<String, dynamic>>()
                .map(CookingStep.fromJson)
                .toList()
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
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      durationMin: json['durationMin'] is int
          ? json['durationMin'] as int
          : (json['DurationMin'] is int ? json['DurationMin'] as int : 0),
    );
  }
}
