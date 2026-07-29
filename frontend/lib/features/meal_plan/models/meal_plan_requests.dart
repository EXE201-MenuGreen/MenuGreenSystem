/// Request DTOs cho Meal Plan API
library;

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
  final String? origin;
  final String? customName;

  CreateItemRequest({
    required this.mealType,
    this.scheduledTime,
    this.foodId,
    this.recipeId,
    this.targetCalories,
    this.quantityG,
    this.origin,
    this.customName,
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
      if (origin != null) 'origin': origin,
      if (customName != null) 'customName': customName,
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
  final DateTime? scheduledTime;
  final DateTime? plannedDate;
  final String? foodId;
  final String? recipeId;
  final int? targetCalories;
  final double? quantityG;
  final String? origin;
  final String? customName;

  AddItemRequest({
    required this.mealType,
    this.scheduledTime,
    this.plannedDate,
    this.foodId,
    this.recipeId,
    this.targetCalories,
    this.quantityG,
    this.origin,
    this.customName,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      if (scheduledTime != null)
        'scheduledTime': scheduledTime!.toIso8601String(),
      if (plannedDate != null) 'plannedDate': _dateOnlyFmt(plannedDate!),
      if (foodId != null) 'foodId': foodId,
      if (recipeId != null) 'recipeId': recipeId,
      if (targetCalories != null) 'targetCalories': targetCalories,
      if (quantityG != null) 'quantityG': quantityG,
      if (origin != null) 'origin': origin,
      if (customName != null) 'customName': customName,
    };
  }

  static String _dateOnlyFmt(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  CreateItemRequest toCreateItemRequest() {
    return CreateItemRequest(
      mealType: mealType,
      scheduledTime: scheduledTime,
      foodId: foodId,
      recipeId: recipeId,
      targetCalories: targetCalories,
      quantityG: quantityG,
      origin: origin,
      customName: customName,
    );
  }
}

class ConvertToLogRequest {
  final DateTime? loggedAt;
  final double? quantityG;

  ConvertToLogRequest({this.loggedAt, this.quantityG});

  Map<String, dynamic> toJson() {
    return {
      if (loggedAt != null) 'loggedAt': loggedAt!.toIso8601String(),
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

/// Item origin enum - phân biệt nguồn tạo item
enum ItemOrigin {
  /// Item được tạo thủ công bởi user trong tab Kế hoạch
  user('user'),

  /// Item được tạo tự động bởi AI Gym Goals trong tab Mục tiêu
  gym('gym');

  final String value;
  const ItemOrigin(this.value);

  static ItemOrigin? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'user':
        return ItemOrigin.user;
      case 'gym':
        return ItemOrigin.gym;
      default:
        return null;
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

/// Office scan meal request for saving scanned meals
class OfficeScanMealRequest {
  final String customName;
  final String mealType;
  final DateTime plannedDate;
  final DateTime? scheduledTime;
  final double quantityG;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime? loggedAt;
  final bool replaceExisting;
  final List<OfficeScanIngredientRequest> ingredients;

  OfficeScanMealRequest({
    required this.customName,
    required this.mealType,
    required this.plannedDate,
    this.scheduledTime,
    required this.quantityG,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.loggedAt,
    this.replaceExisting = false,
    this.ingredients = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'customName': customName,
      'mealType': mealType,
      'plannedDate': _dateOnly(plannedDate),
      if (scheduledTime != null) 'scheduledTime': _timeOnly(scheduledTime!),
      'quantityG': quantityG,
      'caloriesKcal': caloriesKcal,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      if (loggedAt != null) 'loggedAt': loggedAt!.toIso8601String(),
      'replaceExisting': replaceExisting,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _timeOnly(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// Office scan ingredient request
class OfficeScanIngredientRequest {
  final String name;
  final double quantity;
  final String unit;
  final bool isAvailable;

  OfficeScanIngredientRequest({
    required this.name,
    required this.quantity,
    this.unit = 'g',
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isAvailable': isAvailable,
    };
  }
}
