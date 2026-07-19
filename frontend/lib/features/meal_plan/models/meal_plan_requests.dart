/// Request DTOs cho Meal Plan API
library;

class OfficeScanIngredientRequest {
  const OfficeScanIngredientRequest({
    required this.name,
    required this.quantity,
    this.unit = 'g',
    this.isAvailable = true,
  });

  final String name;
  final double quantity;
  final String unit;
  final bool isAvailable;

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'isAvailable': isAvailable,
  };
}

class OfficeScanMealRequest {
  const OfficeScanMealRequest({
    required this.customName,
    required this.mealType,
    required this.plannedDate,
    required this.quantityG,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.ingredients,
    this.replaceExisting = false,
    this.loggedAt,
  });

  final String customName;
  final String mealType;
  final DateTime plannedDate;
  final double quantityG;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<OfficeScanIngredientRequest> ingredients;
  final bool replaceExisting;
  final DateTime? loggedAt;

  Map<String, dynamic> toJson() => {
    'customName': customName,
    'mealType': mealType,
    'plannedDate': _dateOnly(plannedDate),
    'scheduledTime': '12:00:00',
    'quantityG': quantityG,
    'caloriesKcal': caloriesKcal,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'replaceExisting': replaceExisting,
    'loggedAt': (loggedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
  };

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CreatePlanRequest {
  final String title;
  final String planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final String? notes;
  final bool isActive;

  CreatePlanRequest({
    required this.title,
    required this.planType,
    this.startDate,
    this.endDate,
    this.targetCalories,
    this.notes,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'planType': planType,
      if (startDate != null) 'startDate': _dateOnly(startDate!),
      if (endDate != null) 'endDate': _dateOnly(endDate!),
      if (targetCalories != null) 'targetCalories': targetCalories,
      if (notes != null) 'notes': notes,
      'isActive': isActive,
    };
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CreateEmptyPlanRequest {
  final String title;
  final String planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final bool isActive;

  CreateEmptyPlanRequest({
    required this.title,
    required this.planType,
    this.startDate,
    this.endDate,
    this.targetCalories,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'planType': planType,
      if (startDate != null) 'startDate': _dateOnly(startDate!),
      if (endDate != null) 'endDate': _dateOnly(endDate!),
      if (targetCalories != null) 'targetCalories': targetCalories,
      'isActive': isActive,
    };
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Request để tạo kế hoạch với items ngay từ đầu
class CreatePlanWithItemsRequest {
  final String title;
  final String planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final bool isActive;
  final List<CreateItemRequest> items;

  CreatePlanWithItemsRequest({
    required this.title,
    required this.planType,
    this.startDate,
    this.endDate,
    this.targetCalories,
    this.isActive = true,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'planType': planType,
      if (startDate != null) 'startDate': _dateOnly(startDate!),
      if (endDate != null) 'endDate': _dateOnly(endDate!),
      if (targetCalories != null) 'targetCalories': targetCalories,
      'isActive': isActive,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Item request dùng khi tạo plan với items
class CreateItemRequest {
  final String mealType;
  final DateTime? scheduledTime;
  final String? foodId;
  final String? recipeId;
  final int? targetCalories;
  final double? quantityG;

  CreateItemRequest({
    required this.mealType,
    this.scheduledTime,
    this.foodId,
    this.recipeId,
    this.targetCalories,
    this.quantityG,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      if (scheduledTime != null)
        'scheduledTime': scheduledTime!.toIso8601String(),
      if (foodId != null) 'foodId': foodId,
      if (recipeId != null) 'recipeId': recipeId,
      if (targetCalories != null) 'targetCalories': targetCalories,
      if (quantityG != null) 'quantityG': quantityG,
    };
  }
}

class DuplicatePlanRequest {
  final DateTime newStartDate;
  final DateTime? newEndDate;

  DuplicatePlanRequest({required this.newStartDate, this.newEndDate});

  Map<String, dynamic> toJson() {
    return {
      'newStartDate': _dateOnly(newStartDate),
      if (newEndDate != null) 'newEndDate': _dateOnly(newEndDate!),
    };
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class AddItemRequest {
  final String mealType;
  final DateTime? plannedDate;
  final DateTime? scheduledTime;
  final String? foodId;
  final String? recipeId;
  final int? targetCalories;
  final double? quantityG;

  AddItemRequest({
    required this.mealType,
    this.plannedDate,
    this.scheduledTime,
    this.foodId,
    this.recipeId,
    this.targetCalories,
    this.quantityG,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      if (plannedDate != null) 'plannedDate': _dateOnly(plannedDate!),
      if (scheduledTime != null) 'scheduledTime': _timeOnly(scheduledTime!),
      if (foodId != null) 'foodId': foodId,
      if (recipeId != null) 'recipeId': recipeId,
      if (targetCalories != null) 'targetCalories': targetCalories,
      if (quantityG != null) 'quantityG': quantityG,
    };
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _timeOnly(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:00';
  }

  CreateItemRequest toCreateItemRequest() {
    return CreateItemRequest(
      mealType: mealType,
      scheduledTime: scheduledTime,
      foodId: foodId,
      recipeId: recipeId,
      targetCalories: targetCalories,
      quantityG: quantityG,
    );
  }
}

class ConvertToLogRequest {
  final DateTime loggedAt;
  final double? quantityG;

  ConvertToLogRequest({required this.loggedAt, this.quantityG});

  Map<String, dynamic> toJson() {
    return {
      'loggedAt': loggedAt.toIso8601String(),
      if (quantityG != null) 'quantityG': quantityG,
    };
  }
}

class UpdateItemStatusRequest {
  final String status;

  UpdateItemStatusRequest({required this.status});

  Map<String, dynamic> toJson() => {'status': status};
}

/// Item status enum
enum ItemStatus {
  planned('planned'),
  done('done'),
  skipped('skipped'),
  changed('changed');

  final String value;
  const ItemStatus(this.value);

  static ItemStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'done':
        return ItemStatus.done;
      case 'skipped':
        return ItemStatus.skipped;
      case 'changed':
        return ItemStatus.changed;
      default:
        return ItemStatus.planned;
    }
  }
}

/// Plan type enum
enum PlanType {
  daily('daily'),
  weekly('weekly'),
  custom('custom');

  final String value;
  const PlanType(this.value);

  static PlanType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'daily':
        return PlanType.daily;
      case 'custom':
        return PlanType.custom;
      default:
        return PlanType.weekly;
    }
  }
}

/// Meal type enum
enum MealType {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snack('snack');

  final String value;
  const MealType(this.value);

  static MealType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      default:
        return MealType.snack;
    }
  }

  String get labelVi {
    switch (this) {
      case MealType.breakfast:
        return 'Bữa sáng';
      case MealType.lunch:
        return 'Bữa trưa';
      case MealType.dinner:
        return 'Bữa tối';
      case MealType.snack:
        return 'Bữa phụ';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🍳';
      case MealType.lunch:
        return '🍱';
      case MealType.dinner:
        return '🍽️';
      case MealType.snack:
        return '🍿';
    }
  }

  double get caloriesRatio {
    switch (this) {
      case MealType.breakfast:
        return 0.25;
      case MealType.lunch:
        return 0.35;
      case MealType.dinner:
        return 0.30;
      case MealType.snack:
        return 0.10;
    }
  }

  int getCaloriesTarget(int totalCalories) {
    return (totalCalories * caloriesRatio).round();
  }
}
