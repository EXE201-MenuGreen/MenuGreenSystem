/// Additional response models cho Meal Plan
library;

class MealPlanListItem {
  final String id;
  final String title;
  final String? planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final bool isActive;
  final int completedItems;
  final int totalItems;
  final int currentStreak;

  MealPlanListItem({
    required this.id,
    required this.title,
    this.planType,
    this.startDate,
    this.endDate,
    this.targetCalories,
    required this.isActive,
    required this.completedItems,
    required this.totalItems,
    this.currentStreak = 0,
  });

  factory MealPlanListItem.fromJson(Map<String, dynamic> json) {
    return MealPlanListItem(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      planType: (json['planType'] ?? json['PlanType'])?.toString(),
      startDate: _parseDate(json['startDate'] ?? json['StartDate']),
      endDate: _parseDate(json['endDate'] ?? json['EndDate']),
      targetCalories: _int(json['targetCalories'] ?? json['TargetCalories']),
      isActive: json['isActive'] == true || json['IsActive'] == true,
      completedItems: _int(json['completedItems'] ?? json['CompletedItems'] ?? 0),
      totalItems: _int(json['totalItems'] ?? json['TotalItems'] ?? 0),
      currentStreak: _int(json['currentStreak'] ?? json['CurrentStreak'] ?? 0),
    );
  }

  String get dateRangeText {
    if (startDate == null) return '';
    if (endDate == null) {
      return _formatDate(startDate!);
    }
    return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class MealPlanDetail {
  final String id;
  final String title;
  final String? planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final int? targetProtein;
  final int? targetCarbs;
  final int? targetFat;
  final bool isActive;
  final String? notes;
  final int totalCalories;
  final int totalProteinG;
  final int totalCarbsG;
  final int totalFatG;
  final List<MealPlanItemDetail> items;

  MealPlanDetail({
    required this.id,
    required this.title,
    this.planType,
    this.startDate,
    this.endDate,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    required this.isActive,
    this.notes,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.items,
  });

  factory MealPlanDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? [];
    return MealPlanDetail(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      planType: (json['planType'] ?? json['PlanType'])?.toString(),
      startDate: _parseDate(json['startDate'] ?? json['StartDate']),
      endDate: _parseDate(json['endDate'] ?? json['EndDate']),
      targetCalories: _int(json['targetCalories'] ?? json['TargetCalories']),
      targetProtein: _int(json['targetProteinG'] ?? json['TargetProteinG']),
      targetCarbs: _int(json['targetCarbsG'] ?? json['TargetCarbsG']),
      targetFat: _int(json['targetFatG'] ?? json['TargetFatG']),
      isActive: json['isActive'] == true || json['IsActive'] == true,
      notes: (json['notes'] ?? json['Notes'])?.toString(),
      totalCalories: _int(json['totalCalories'] ?? json['TotalCalories'] ?? 0),
      totalProteinG: _int(json['totalProteinG'] ?? json['TotalProteinG'] ?? 0),
      totalCarbsG: _int(json['totalCarbsG'] ?? json['TotalCarbsG'] ?? 0),
      totalFatG: _int(json['totalFatG'] ?? json['TotalFatG'] ?? 0),
      items: (rawItems as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => MealPlanItemDetail.fromJson(item))
          .toList(),
    );
  }

  int get completedCount => items.where((i) => i.isCompleted || i.status == 'done').length;
  int get totalCount => items.length;
  double get completionPercent => totalCount > 0 ? completedCount / totalCount : 0;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class MealPlanItemDetail {
  final String id;
  final String? mealPlanId;
  final String? mealType;
  final String? foodId;
  final String? recipeId;
  final DateTime? plannedDate;
  final DateTime? scheduledTime;
  final int? targetCalories;
  final bool isCompleted;
  final String? mealLogId;
  final String? foodName;
  final String? recipeName;
  final String? sourceEntityType;
  final String? status;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final double? quantityG;

  MealPlanItemDetail({
    required this.id,
    this.mealPlanId,
    this.mealType,
    this.foodId,
    this.recipeId,
    this.plannedDate,
    this.scheduledTime,
    this.targetCalories,
    required this.isCompleted,
    this.mealLogId,
    this.foodName,
    this.recipeName,
    this.sourceEntityType,
    this.status,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.quantityG,
  });

  factory MealPlanItemDetail.fromJson(Map<String, dynamic> json) {
    return MealPlanItemDetail(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      mealPlanId: (json['mealPlanId'] ?? json['MealPlanId'])?.toString(),
      mealType: (json['mealType'] ?? json['MealType'])?.toString(),
      foodId: (json['foodId'] ?? json['FoodId'])?.toString(),
      recipeId: (json['recipeId'] ?? json['RecipeId'])?.toString(),
      plannedDate: _parseDateTime(json['plannedDate'] ?? json['PlannedDate']),
      scheduledTime: _parseTime(json['scheduledTime'] ?? json['ScheduledTime']),
      targetCalories: _int(json['targetCalories'] ?? json['TargetCalories']),
      isCompleted: json['isCompleted'] == true || json['IsCompleted'] == true,
      mealLogId: (json['mealLogId'] ?? json['MealLogId'])?.toString(),
      foodName: (json['foodName'] ?? json['FoodName'])?.toString(),
      recipeName: (json['recipeName'] ?? json['RecipeName'])?.toString(),
      sourceEntityType: (json['sourceEntityType'] ?? json['SourceEntityType'])?.toString(),
      status: (json['status'] ?? json['Status'] ?? 'planned').toString(),
      proteinG: _int(json['proteinG'] ?? json['ProteinG']),
      carbsG: _int(json['carbsG'] ?? json['CarbsG']),
      fatG: _int(json['fatG'] ?? json['FatG']),
      quantityG: (json['quantityG'] ?? json['QuantityG'] ?? json['quantity'] ?? json['Quantity'])?.toDouble(),
    );
  }

  String get displayName {
    final name = (foodName ?? recipeName ?? '').trim();
    return name.isNotEmpty ? name : 'Món trong kế hoạch';
  }

  bool get isFood =>
      (sourceEntityType ?? '').toLowerCase() == 'food' || (foodId != null && recipeId == null);

  bool get isDone => isCompleted || status == 'done' || status == 'completed';

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class ConvertToLogResult {
  final bool success;
  final String? mealLogId;
  final String? message;

  ConvertToLogResult({
    required this.success,
    this.mealLogId,
    this.message,
  });

  factory ConvertToLogResult.fromJson(Map<String, dynamic> json) {
    return ConvertToLogResult(
      success: json['success'] == true || json['Success'] == true,
      mealLogId: (json['mealLogId'] ?? json['MealLogId'])?.toString(),
      message: (json['message'] ?? json['Message'])?.toString(),
    );
  }
}

class MealPlanDayDashboard {
  final DateTime date;
  final int plannedCalories;
  final int actualCalories;
  final int plannedProtein;
  final int actualProtein;
  final int plannedCarbs;
  final int actualCarbs;
  final int plannedFat;
  final int actualFat;
  final int completedMeals;
  final int totalMeals;
  final double adherencePercent;
  final List<MealPlanItemDetail> plannedItems;
  final List<MealPlanItemDetail> completedItems;

  MealPlanDayDashboard({
    required this.date,
    required this.plannedCalories,
    required this.actualCalories,
    required this.plannedProtein,
    required this.actualProtein,
    required this.plannedCarbs,
    required this.actualCarbs,
    required this.plannedFat,
    required this.actualFat,
    required this.completedMeals,
    required this.totalMeals,
    required this.adherencePercent,
    required this.plannedItems,
    required this.completedItems,
  });

  factory MealPlanDayDashboard.fromJson(Map<String, dynamic> json) {
    return MealPlanDayDashboard(
      date: DateTime.parse(json['date'] ?? json['Date']),
      plannedCalories: _int(json['plannedCalories'] ?? json['PlannedCalories'] ?? 0),
      actualCalories: _int(json['actualCalories'] ?? json['ActualCalories'] ?? 0),
      plannedProtein: _int(json['plannedProtein'] ?? json['PlannedProtein'] ?? 0),
      actualProtein: _int(json['actualProtein'] ?? json['ActualProtein'] ?? 0),
      plannedCarbs: _int(json['plannedCarbs'] ?? json['PlannedCarbs'] ?? 0),
      actualCarbs: _int(json['actualCarbs'] ?? json['ActualCarbs'] ?? 0),
      plannedFat: _int(json['plannedFat'] ?? json['PlannedFat'] ?? 0),
      actualFat: _int(json['actualFat'] ?? json['ActualFat'] ?? 0),
      completedMeals: _int(json['completedMeals'] ?? json['CompletedMeals'] ?? 0),
      totalMeals: _int(json['totalMeals'] ?? json['TotalMeals'] ?? 0),
      adherencePercent: (json['adherencePercent'] ?? json['AdherencePercent'] ?? 0).toDouble(),
      plannedItems: (json['plannedItems'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => MealPlanItemDetail.fromJson(item))
          .toList(),
      completedItems: (json['completedItems'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => MealPlanItemDetail.fromJson(item))
          .toList(),
    );
  }
}

class MealPlanCompare {
  final DateTime from;
  final DateTime to;
  final int plannedCalories;
  final int actualCalories;
  final double caloriePercent;
  final int plannedProtein;
  final int actualProtein;
  final double proteinPercent;
  final int plannedCarbs;
  final int actualCarbs;
  final double carbsPercent;
  final int plannedFat;
  final int actualFat;
  final double fatPercent;
  final int completedDays;
  final int totalDays;
  final List<WeekCompare> weeklyData;

  MealPlanCompare({
    required this.from,
    required this.to,
    required this.plannedCalories,
    required this.actualCalories,
    required this.caloriePercent,
    required this.plannedProtein,
    required this.actualProtein,
    required this.proteinPercent,
    required this.plannedCarbs,
    required this.actualCarbs,
    required this.carbsPercent,
    required this.plannedFat,
    required this.actualFat,
    required this.fatPercent,
    required this.completedDays,
    required this.totalDays,
    required this.weeklyData,
  });

  factory MealPlanCompare.fromJson(Map<String, dynamic> json) {
    return MealPlanCompare(
      from: DateTime.parse(json['from'] ?? json['From']),
      to: DateTime.parse(json['to'] ?? json['To']),
      plannedCalories: _int(json['plannedCalories'] ?? json['PlannedCalories'] ?? 0),
      actualCalories: _int(json['actualCalories'] ?? json['ActualCalories'] ?? 0),
      caloriePercent: (json['caloriePercent'] ?? json['CaloriePercent'] ?? 0).toDouble(),
      plannedProtein: _int(json['plannedProtein'] ?? json['PlannedProtein'] ?? 0),
      actualProtein: _int(json['actualProtein'] ?? json['ActualProtein'] ?? 0),
      proteinPercent: (json['proteinPercent'] ?? json['ProteinPercent'] ?? 0).toDouble(),
      plannedCarbs: _int(json['plannedCarbs'] ?? json['PlannedCarbs'] ?? 0),
      actualCarbs: _int(json['actualCarbs'] ?? json['ActualCarbs'] ?? 0),
      carbsPercent: (json['carbsPercent'] ?? json['CarbsPercent'] ?? 0).toDouble(),
      plannedFat: _int(json['plannedFat'] ?? json['PlannedFat'] ?? 0),
      actualFat: _int(json['actualFat'] ?? json['ActualFat'] ?? 0),
      fatPercent: (json['fatPercent'] ?? json['FatPercent'] ?? 0).toDouble(),
      completedDays: _int(json['completedDays'] ?? json['CompletedDays'] ?? 0),
      totalDays: _int(json['totalDays'] ?? json['TotalDays'] ?? 0),
      weeklyData: (json['weeklyData'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => WeekCompare.fromJson(item))
          .toList(),
    );
  }
}

class WeekCompare {
  final int weekNumber;
  final int plannedCalories;
  final int actualCalories;
  final double percent;

  WeekCompare({
    required this.weekNumber,
    required this.plannedCalories,
    required this.actualCalories,
    required this.percent,
  });

  factory WeekCompare.fromJson(Map<String, dynamic> json) {
    return WeekCompare(
      weekNumber: _int(json['weekNumber'] ?? json['WeekNumber']),
      plannedCalories: _int(json['plannedCalories'] ?? json['PlannedCalories'] ?? 0),
      actualCalories: _int(json['actualCalories'] ?? json['ActualCalories'] ?? 0),
      percent: (json['percent'] ?? json['Percent'] ?? 0).toDouble(),
    );
  }
}

class MealPlanStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int totalCompletedDays;
  final double averageAdherence;

  MealPlanStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
    required this.totalCompletedDays,
    required this.averageAdherence,
  });

  factory MealPlanStreak.fromJson(Map<String, dynamic> json) {
    return MealPlanStreak(
      currentStreak: _int(json['currentStreak'] ?? json['CurrentStreak'] ?? 0),
      longestStreak: _int(json['longestStreak'] ?? json['LongestStreak'] ?? 0),
      lastCompletedDate: _parseDate(json['lastCompletedDate'] ?? json['LastCompletedDate']),
      totalCompletedDays: _int(json['totalCompletedDays'] ?? json['TotalCompletedDays'] ?? 0),
      averageAdherence: (json['averageAdherence'] ?? json['AverageAdherence'] ?? 0).toDouble(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  return 0;
}

class DayPlanSummary {
  final int plannedCalories;
  final int actualCalories;
  final int completedItems;
  final int totalItems;
  final double adherencePercent;

  DayPlanSummary({
    required this.plannedCalories,
    required this.actualCalories,
    required this.completedItems,
    required this.totalItems,
    required this.adherencePercent,
  });

  factory DayPlanSummary.fromJson(Map<String, dynamic> json) {
    return DayPlanSummary(
      plannedCalories: _int(json['plannedCalories'] ?? json['PlannedCalories'] ?? 0),
      actualCalories: _int(json['actualCalories'] ?? json['ActualCalories'] ?? 0),
      completedItems: _int(json['completedItems'] ?? json['CompletedItems'] ?? 0),
      totalItems: _int(json['totalItems'] ?? json['TotalItems'] ?? 0),
      adherencePercent: (json['adherencePercent'] ?? json['AdherencePercent'] ?? 0).toDouble(),
    );
  }

  int get completedMeals => completedItems;
  int get totalMeals => totalItems;
  bool get isCompleted => completedItems == totalItems && totalItems > 0;
  bool get hasData => totalItems > 0;
}
