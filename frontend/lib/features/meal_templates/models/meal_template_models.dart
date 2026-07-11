class MealTemplateItem {
  const MealTemplateItem({
    required this.id,
    this.foodId,
    this.recipeId,
    this.name,
    this.mealType,
    required this.quantityG,
    this.notes,
    required this.sortOrder,
    this.caloriesKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final String id;
  final String? foodId;
  final String? recipeId;
  final String? name;
  final String? mealType;
  final double quantityG;
  final String? notes;
  final int sortOrder;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  bool get isRecipe => recipeId != null && recipeId!.isNotEmpty;

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

    return MealTemplateItem(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      foodId: id('foodId'),
      recipeId: id('recipeId'),
      name: json['name']?.toString() ?? json['Name']?.toString(),
      mealType: json['mealType']?.toString() ?? json['MealType']?.toString(),
      quantityG: number('quantityG'),
      notes: json['notes']?.toString() ?? json['Notes']?.toString(),
      sortOrder: number('sortOrder').round(),
      caloriesKcal: number('caloriesKcal'),
      proteinG: number('proteinG'),
      carbsG: number('carbsG'),
      fatG: number('fatG'),
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
    required this.mealType,
    required this.label,
    required this.quantityG,
    this.notes,
  });

  final String? foodId;
  final String? recipeId;
  final String mealType;
  final String label;
  final double quantityG;
  final String? notes;

  Map<String, dynamic> toJson(int sortOrder) => {
        'foodId': foodId,
        'recipeId': recipeId,
        'mealType': mealType,
        'quantityG': quantityG,
        'notes': notes,
        'sortOrder': sortOrder,
      };
}
