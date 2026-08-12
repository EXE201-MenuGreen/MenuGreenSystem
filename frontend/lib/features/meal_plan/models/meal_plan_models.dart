import '../../discover/models/food_models.dart';

class UserMealPlan {
  UserMealPlan({
    required this.id,
    required this.title,
    required this.planType,
    required this.startDate,
    required this.targetCalories,
    required this.items,
    this.generatedBy,
    this.status,
  });

  final String id;
  final String title;
  final String? planType;
  final String? startDate;
  final int targetCalories;
  final List<MealPlanItemModel> items;
  final String? generatedBy;
  final String? status;

  factory UserMealPlan.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'];
    return UserMealPlan(
      id: (json['id'] ?? json['Id']).toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      planType: (json['planType'] ?? json['PlanType'])?.toString(),
      startDate: (json['startDate'] ?? json['StartDate'])?.toString(),
      targetCalories: _int(json['targetCalories'] ?? json['TargetCalories']),
      generatedBy: (json['generatedBy'] ?? json['GeneratedBy'])?.toString(),
      status: (json['status'] ?? json['Status'])?.toString(),
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(MealPlanItemModel.fromJson)
                .toList()
          : [],
    );
  }
}

class MealPlanItemModel {
  MealPlanItemModel({
    required this.id,
    required this.mealType,
    this.foodId,
    this.recipeId,
    required this.targetCalories,
    required this.isCompleted,
    this.foodName,
    this.recipeName,
    this.mealLogId,
    this.plannedDate,
    this.scheduledTime,
    this.sourceEntityType,
    this.origin,
    this.quantityG,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.ingredients = const [],
  });

  final String id;
  final String mealType;
  final String? foodId;
  final String? recipeId;
  final int targetCalories;
  final bool isCompleted;
  final String? foodName;
  final String? recipeName;
  final String? mealLogId;
  final DateTime? plannedDate;
  final String? scheduledTime;
  final String? sourceEntityType;
  final double? quantityG;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final List<RecipeIngredientItem> ingredients;

  /// Nguồn gốc của item: "user" = tạo tay ở tab Kế hoạch,
  /// "gym" = tạo tự động từ AI Gym Goals ở tab Mục tiêu.
  final String? origin;

  String get displayName {
    final name = (foodName ?? recipeName ?? '').trim();
    return name.isNotEmpty ? name : 'Món trong kế hoạch';
  }

  bool get isFood =>
      (sourceEntityType ?? '').toLowerCase() == 'food' ||
      (foodId != null && recipeId == null);

  factory MealPlanItemModel.fromJson(Map<String, dynamic> json) {
    return MealPlanItemModel(
      id: (json['id'] ?? json['Id']).toString(),
      mealType: (json['mealType'] ?? json['MealType'] ?? 'snack').toString(),
      foodId: (json['foodId'] ?? json['FoodId'])?.toString(),
      recipeId: (json['recipeId'] ?? json['RecipeId'])?.toString(),
      targetCalories: _int(json['targetCalories'] ?? json['TargetCalories']),
      isCompleted: json['isCompleted'] == true || json['IsCompleted'] == true,
      foodName: (json['foodName'] ?? json['FoodName'])?.toString(),
      recipeName: (json['recipeName'] ?? json['RecipeName'])?.toString(),
      mealLogId: (json['mealLogId'] ?? json['MealLogId'])?.toString(),
      plannedDate: DateTime.tryParse(
        (json['plannedDate'] ?? json['PlannedDate'] ?? '').toString(),
      ),
      scheduledTime: (json['scheduledTime'] ?? json['ScheduledTime'])
          ?.toString(),
      sourceEntityType: (json['sourceEntityType'] ?? json['SourceEntityType'])
          ?.toString(),
      origin: (json['origin'] ?? json['Origin'])?.toString(),
      quantityG: _nullableDouble(json['quantityG'] ?? json['QuantityG']),
      proteinG: _nullableInt(json['proteinG'] ?? json['ProteinG']),
      carbsG: _nullableInt(json['carbsG'] ?? json['CarbsG']),
      fatG: _nullableInt(json['fatG'] ?? json['FatG']),
      ingredients:
          ((json['ingredients'] ?? json['Ingredients']) as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => RecipeIngredientItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
    );
  }
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

class MealPlanAdherence {
  MealPlanAdherence({
    required this.plannedKcal,
    required this.actualKcal,
    required this.completedCount,
    required this.totalCount,
    this.deviationPercent,
  });

  final int plannedKcal;
  final double actualKcal;
  final int completedCount;
  final int totalCount;
  final double? deviationPercent;

  factory MealPlanAdherence.fromJson(Map<String, dynamic> json) {
    double? dev;
    final rawDev = json['deviationPercent'] ?? json['DeviationPercent'];
    if (rawDev is num) dev = rawDev.toDouble();

    return MealPlanAdherence(
      plannedKcal: _int(json['plannedKcal'] ?? json['PlannedKcal']),
      actualKcal: _double(json['actualKcal'] ?? json['ActualKcal']),
      completedCount: _int(json['completedCount'] ?? json['CompletedCount']),
      totalCount: _int(json['totalCount'] ?? json['TotalCount']),
      deviationPercent: dev,
    );
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  return 0;
}

double _double(dynamic v) {
  if (v is num) return v.toDouble();
  return 0;
}

String mealTypeLabelVi(String mealType) {
  switch (mealType.toLowerCase()) {
    case 'breakfast':
      return 'Bữa sáng';
    case 'lunch':
      return 'Bữa trưa';
    case 'dinner':
      return 'Bữa tối';
    case 'snack':
      return 'Bữa phụ';
    default:
      return mealType;
  }
}
