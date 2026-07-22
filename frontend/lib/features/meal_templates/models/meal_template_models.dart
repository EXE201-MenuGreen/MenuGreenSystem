class MealTemplateIngredient {
  const MealTemplateIngredient({
    required this.name,
    required this.quantity,
    this.unit = 'g',
    this.isAvailable = true,
  });

  final String name;
  final double quantity;
  final String unit;
  final bool isAvailable;

  factory MealTemplateIngredient.fromJson(Map<String, dynamic> json) {
    final rawQuantity = json['quantity'] ?? json['Quantity'];
    return MealTemplateIngredient(
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      quantity: rawQuantity is num
          ? rawQuantity.toDouble()
          : double.tryParse('$rawQuantity') ?? 0,
      unit: (json['unit'] ?? json['Unit'] ?? 'g').toString(),
      isAvailable: (json['isAvailable'] ?? json['IsAvailable']) != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'isAvailable': isAvailable,
  };
}

class MealTemplateItem {
  const MealTemplateItem({
    required this.id,
    this.foodId,
    this.recipeId,
    this.customName,
    this.sourceType,
    this.name,
    this.mealType,
    required this.quantityG,
    this.notes,
    required this.sortOrder,
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.ingredients = const [],
  });

  final String id;
  final String? foodId;
  final String? recipeId;
  final String? customName;
  final String? sourceType;
  final String? name;
  final String? mealType;
  final double quantityG;
  final String? notes;
  final int sortOrder;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<MealTemplateIngredient> ingredients;

  bool get isRecipe => recipeId != null && recipeId!.isNotEmpty;
  bool get isAiScan => sourceType?.toLowerCase() == 'aiscan';

  factory MealTemplateItem.fromJson(Map<String, dynamic> json) {
    double number(String key) {
      final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
      return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    }

    String? id(String key) {
      final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
      final result = value?.toString();
      return result == null || result.isEmpty || result == 'null' ? null : result;
    }

    final rawIngredients = json['ingredients'] ?? json['Ingredients'];
    final customName = id('customName');

    return MealTemplateItem(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      foodId: id('foodId'),
      recipeId: id('recipeId'),
      customName: customName,
      sourceType: id('sourceType'),
      name:
          json['name']?.toString() ??
          json['Name']?.toString() ??
          customName,
      mealType: json['mealType']?.toString() ?? json['MealType']?.toString(),
      quantityG: number('quantityG'),
      notes: json['notes']?.toString() ?? json['Notes']?.toString(),
      sortOrder: number('sortOrder').round(),
      caloriesKcal: number('caloriesKcal'),
      proteinG: number('proteinG'),
      carbsG: number('carbsG'),
      fatG: number('fatG'),
      ingredients: rawIngredients is List
          ? rawIngredients
                .whereType<Map>()
                .map(
                  (item) => MealTemplateIngredient.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class MealTemplate {
  const MealTemplate({
    required this.id,
    required this.title,
    this.description,
    this.mealType,
    required this.usageCount,
    required this.isActive,
    this.items = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? mealType;
  final int usageCount;
  final bool isActive;
  final List<MealTemplateItem> items;

  factory MealTemplate.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'];
    final rawUsageCount = json['usageCount'] ?? json['UsageCount'];
    return MealTemplate(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: json['description']?.toString() ?? json['Description']?.toString(),
      mealType: json['mealType']?.toString() ?? json['MealType']?.toString(),
      usageCount: rawUsageCount is num ? rawUsageCount.toInt() : int.tryParse('$rawUsageCount') ?? 0,
      isActive: (json['isActive'] ?? json['IsActive']) != false,
      items: rawItems is List
          ? rawItems.whereType<Map>().map((item) => MealTemplateItem.fromJson(item.cast<String, dynamic>())).toList()
          : const [],
    );
  }
}

class MealTemplateDraftItem {
  const MealTemplateDraftItem({
    this.foodId,
    this.recipeId,
    this.customName,
    this.sourceType,
    required this.mealType,
    required this.label,
    required this.quantityG,
    this.notes,
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.ingredients = const [],
  });

  final String? foodId;
  final String? recipeId;
  final String? customName;
  final String? sourceType;
  final String mealType;
  final String label;
  final double quantityG;
  final String? notes;
  final double? caloriesKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final List<MealTemplateIngredient> ingredients;

  Map<String, dynamic> toJson(int sortOrder) => {
        'foodId': foodId,
        'recipeId': recipeId,
        'customName': customName,
        'sourceType': sourceType,
        'mealType': mealType,
        'quantityG': quantityG,
        'caloriesKcal': caloriesKcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'ingredients': ingredients.map((item) => item.toJson()).toList(),
        'notes': notes,
        'sortOrder': sortOrder,
      };
}
