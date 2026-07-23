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
    final rawItems = json['items'] ?? json['Items'] ?? const [];
    final items = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final completedFromItems = items.where((item) {
      final status = (item['status'] ?? item['Status'] ?? '')
          .toString()
          .toLowerCase();
      return item['isCompleted'] == true ||
          item['IsCompleted'] == true ||
          status == 'done' ||
          status == 'completed';
    }).length;

    return MealPlanListItem(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      planType: (json['planType'] ?? json['PlanType'])?.toString(),
      startDate: _parseDate(json['startDate'] ?? json['StartDate']),
      endDate: _parseDate(json['endDate'] ?? json['EndDate']),
      targetCalories: _int(json['targetCalories'] ?? json['TargetCalories']),
      isActive: json['isActive'] == true || json['IsActive'] == true,
      completedItems: _int(
        json['completedItems'] ?? json['CompletedItems'] ?? completedFromItems,
      ),
      totalItems: _int(
        json['totalItems'] ?? json['TotalItems'] ?? items.length,
      ),
      currentStreak: _int(json['currentStreak'] ?? json['CurrentStreak'] ?? 0),
    );
  }

  String get dateRangeText {
    if (startDate == null) return '';
    final startStr = _formatDate(startDate!);
    if (endDate == null) return startStr;
    final endStr = _formatDate(endDate!);
    if (startStr == endStr || planType?.toLowerCase() == 'daily') {
      return startStr;
    }
    return '$startStr - $endStr';
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

  int get completedCount =>
      items.where((i) => i.isCompleted || i.status == 'done').length;
  int get totalCount => items.length;
  double get completionPercent =>
      totalCount > 0 ? completedCount / totalCount : 0;

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
  /// Ngu?n g?c: "user" = t?o tay ? tab K? ho?ch,
  /// "gym" = t?o t? ??ng t? AI Gym Goals ? tab M?c ti?u.
  final String? origin;

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
    this.origin,
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
      sourceEntityType: (json['sourceEntityType'] ?? json['SourceEntityType'])
          ?.toString(),
      status: (json['status'] ?? json['Status'] ?? 'planned').toString(),
      proteinG: _int(json['proteinG'] ?? json['ProteinG']),
      carbsG: _int(json['carbsG'] ?? json['CarbsG']),
      fatG: _int(json['fatG'] ?? json['FatG']),
      quantityG:
          (json['quantityG'] ??
                  json['QuantityG'] ??
                  json['quantity'] ??
                  json['Quantity'])
              ?.toDouble(),
      origin: (json['origin'] ?? json['Origin'])?.toString(),
    );
  }

  String get displayName {
    final name = (foodName ?? recipeName ?? '').trim();
    return name.isNotEmpty ? name : 'M?n trong k? ho?ch';
  }

  bool get isFood =>
      (sourceEntityType ?? '').toLowerCase() == 'food' ||
      (foodId != null && recipeId == null);

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

  ConvertToLogResult({required this.success, this.mealLogId, this.message});

  factory ConvertToLogResult.fromJson(Map<String, dynamic> json) {
    final id =
        json['mealLogId'] ?? json['MealLogId'] ?? json['id'] ?? json['Id'];
    return ConvertToLogResult(
      success: json['success'] == true || json['Success'] == true || id != null,
      mealLogId: id?.toString(),
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
    final rawItems =
        json['plannedItems'] ??
        json['PlannedItems'] ??
        json['items'] ??
        json['Items'] ??
        const [];
    final plannedItems = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(MealPlanItemDetail.fromJson)
              .toList()
        : <MealPlanItemDetail>[];
    final completedItems = plannedItems.where((item) => item.isDone).toList();
    final rawActualLogs = json['actualLogs'] ?? json['ActualLogs'] ?? const [];
    final actualLogs = rawActualLogs is List
        ? rawActualLogs.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];

    int sumItems(int? Function(MealPlanItemDetail item) selector) =>
        plannedItems.fold(0, (sum, item) => sum + (selector(item) ?? 0));
    int sumCompleted(int? Function(MealPlanItemDetail item) selector) =>
        completedItems.fold(0, (sum, item) => sum + (selector(item) ?? 0));
    int sumLogs(String camelCaseKey, String pascalCaseKey) => actualLogs.fold(
      0,
      (sum, log) => sum + _int(log[camelCaseKey] ?? log[pascalCaseKey]),
    );
    int valueOrFallback(
      String camelCaseKey,
      String pascalCaseKey,
      int fallback,
    ) {
      final value = json[camelCaseKey] ?? json[pascalCaseKey];
      return value == null ? fallback : _int(value);
    }

    final rawAdherence =
        (json['adherencePercent'] ??
                json['AdherencePercent'] ??
                json['completionRate'] ??
                json['CompletionRate'] ??
                0)
            .toDouble();

    return MealPlanDayDashboard(
      date: DateTime.parse(json['date'] ?? json['Date']),
      plannedCalories: valueOrFallback(
        'plannedCalories',
        'PlannedCalories',
        valueOrFallback(
          'totalPlannedCalories',
          'TotalPlannedCalories',
          sumItems((item) => item.targetCalories),
        ),
      ),
      actualCalories: valueOrFallback(
        'actualCalories',
        'ActualCalories',
        valueOrFallback(
          'totalActualCalories',
          'TotalActualCalories',
          actualLogs.isNotEmpty
              ? sumLogs('caloriesKcal', 'CaloriesKcal')
              : sumCompleted((item) => item.targetCalories),
        ),
      ),
      plannedProtein: valueOrFallback(
        'plannedProtein',
        'PlannedProtein',
        sumItems((item) => item.proteinG),
      ),
      actualProtein: valueOrFallback(
        'actualProtein',
        'ActualProtein',
        actualLogs.isNotEmpty
            ? sumLogs('proteinG', 'ProteinG')
            : sumCompleted((item) => item.proteinG),
      ),
      plannedCarbs: valueOrFallback(
        'plannedCarbs',
        'PlannedCarbs',
        sumItems((item) => item.carbsG),
      ),
      actualCarbs: valueOrFallback(
        'actualCarbs',
        'ActualCarbs',
        actualLogs.isNotEmpty
            ? sumLogs('carbsG', 'CarbsG')
            : sumCompleted((item) => item.carbsG),
      ),
      plannedFat: valueOrFallback(
        'plannedFat',
        'PlannedFat',
        sumItems((item) => item.fatG),
      ),
      actualFat: valueOrFallback(
        'actualFat',
        'ActualFat',
        actualLogs.isNotEmpty
            ? sumLogs('fatG', 'FatG')
            : sumCompleted((item) => item.fatG),
      ),
      completedMeals: valueOrFallback(
        'completedMeals',
        'CompletedMeals',
        valueOrFallback(
          'completedItemsCount',
          'CompletedItemsCount',
          completedItems.length,
        ),
      ),
      totalMeals: valueOrFallback(
        'totalMeals',
        'TotalMeals',
        valueOrFallback(
          'plannedItemsCount',
          'PlannedItemsCount',
          plannedItems.length,
        ),
      ),
      adherencePercent: rawAdherence > 1 ? rawAdherence / 100 : rawAdherence,
      plannedItems: plannedItems,
      completedItems: completedItems,
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
    final rawWeeklyData = json['weeklyData'] ?? json['WeeklyData'] ?? const [];
    return MealPlanCompare(
      from: DateTime.parse(json['from'] ?? json['From']),
      to: DateTime.parse(json['to'] ?? json['To']),
      plannedCalories: _int(
        json['plannedCalories'] ?? json['PlannedCalories'] ?? 0,
      ),
      actualCalories: _int(
        json['actualCalories'] ?? json['ActualCalories'] ?? 0,
      ),
      caloriePercent: (json['caloriePercent'] ?? json['CaloriePercent'] ?? 0)
          .toDouble(),
      plannedProtein: _int(
        json['plannedProtein'] ?? json['PlannedProtein'] ?? 0,
      ),
      actualProtein: _int(json['actualProtein'] ?? json['ActualProtein'] ?? 0),
      proteinPercent: (json['proteinPercent'] ?? json['ProteinPercent'] ?? 0)
          .toDouble(),
      plannedCarbs: _int(json['plannedCarbs'] ?? json['PlannedCarbs'] ?? 0),
      actualCarbs: _int(json['actualCarbs'] ?? json['ActualCarbs'] ?? 0),
      carbsPercent: (json['carbsPercent'] ?? json['CarbsPercent'] ?? 0)
          .toDouble(),
      plannedFat: _int(json['plannedFat'] ?? json['PlannedFat'] ?? 0),
      actualFat: _int(json['actualFat'] ?? json['ActualFat'] ?? 0),
      fatPercent: (json['fatPercent'] ?? json['FatPercent'] ?? 0).toDouble(),
      completedDays: _int(json['completedDays'] ?? json['CompletedDays'] ?? 0),
      totalDays: _int(json['totalDays'] ?? json['TotalDays'] ?? 0),
      weeklyData: (rawWeeklyData as List? ?? [])
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
      plannedCalories: _int(
        json['plannedCalories'] ?? json['PlannedCalories'] ?? 0,
      ),
      actualCalories: _int(
        json['actualCalories'] ?? json['ActualCalories'] ?? 0,
      ),
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
    final rawAdherence =
        (json['weeklyAdherenceRate'] ??
                json['WeeklyAdherenceRate'] ??
                json['averageAdherence'] ??
                json['AverageAdherence'] ??
                0)
            .toDouble();

    return MealPlanStreak(
      currentStreak: _int(
        json['currentStreakDays'] ??
            json['CurrentStreakDays'] ??
            json['currentStreak'] ??
            json['CurrentStreak'] ??
            0,
      ),
      longestStreak: _int(
        json['bestStreakDays'] ??
            json['BestStreakDays'] ??
            json['longestStreak'] ??
            json['LongestStreak'] ??
            0,
      ),
      lastCompletedDate: _parseDate(
        json['lastTrackedDate'] ??
            json['LastTrackedDate'] ??
            json['lastCompletedDate'] ??
            json['LastCompletedDate'],
      ),
      totalCompletedDays: _int(
        json['totalTrackedDays'] ??
            json['TotalTrackedDays'] ??
            json['totalCompletedDays'] ??
            json['TotalCompletedDays'] ??
            0,
      ),
      averageAdherence: rawAdherence > 1 ? rawAdherence / 100 : rawAdherence,
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
      plannedCalories: _int(
        json['plannedCalories'] ?? json['PlannedCalories'] ?? 0,
      ),
      actualCalories: _int(
        json['actualCalories'] ?? json['ActualCalories'] ?? 0,
      ),
      completedItems: _int(
        json['completedItems'] ?? json['CompletedItems'] ?? 0,
      ),
      totalItems: _int(json['totalItems'] ?? json['TotalItems'] ?? 0),
      adherencePercent:
          (json['adherencePercent'] ?? json['AdherencePercent'] ?? 0)
              .toDouble(),
    );
  }

  int get completedMeals => completedItems;
  int get totalMeals => totalItems;
  bool get isCompleted => completedItems == totalItems && totalItems > 0;
  bool get hasData => totalItems > 0;
}
