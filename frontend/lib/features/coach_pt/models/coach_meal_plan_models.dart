/// ----------------------------------------------------------------------------
/// Coach-side meal-plan models (Phase 1 backend response shapes).
/// These wrap the raw [Map<String, dynamic>] payloads returned by
/// [AdvancedRepository.clientMealPlans] / `createClientMealPlan` /
/// `updateClientMealPlan` / `submitClientMealPlan`.
///
/// These are intentionally lightweight "shape" classes with named
/// accessors and fromJson methods — they do not enforce full immutability
/// and do not contain UI logic. UI screens should use them via `CoachPtProvider`
/// (to be added in Phase 4).
/// ----------------------------------------------------------------------------
library;

String coachMealPlanStatusLabel(String status) {
  return switch (status.trim().toLowerCase()) {
    'approved' => 'Đã duyệt & gửi',
    'draft' => 'Bản nháp',
    'active' => 'Chưa duyệt',
    'pending' || 'submitted' => 'Chờ duyệt',
    'pendingacceptance' => 'Chờ Gymer chấp nhận',
    'rejected' => 'Gymer đã từ chối',
    _ => status,
  };
}

String coachMealPlanTypeLabel(String planType) {
  return switch (planType.trim().toLowerCase()) {
    'daily' || 'day' => 'Ngày:',
    'weekly' || 'week' => 'Tuần:',
    'monthly' || 'month' => 'Tháng:',
    _ => '${planType.trim()}:',
  };
}

String coachMealPlanDisplayTitle({
  required String title,
  required String planType,
  DateTime? startDate,
}) {
  final trimmedTitle = title.trim();
  final isDaily = {'daily', 'day'}.contains(planType.trim().toLowerCase());
  final legacyDailyTitle = RegExp(
    r'^Daily plan (\d{4}-\d{2}-\d{2})$',
    caseSensitive: false,
  ).firstMatch(trimmedTitle);

  if (isDaily && (trimmedTitle.isEmpty || legacyDailyTitle != null)) {
    final date =
        startDate ?? DateTime.tryParse(legacyDailyTitle?.group(1) ?? '');
    if (date != null) {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return 'Kế hoạch dinh dưỡng $day-$month-${date.year}';
    }
  }

  return trimmedTitle.isEmpty ? 'Lộ trình ăn uống' : trimmedTitle;
}

class CoachMealPlanListItem {
  CoachMealPlanListItem({
    required this.id,
    required this.title,
    required this.planType,
    this.startDate,
    this.endDate,
    this.targetCalories,
    this.minCalories,
    this.maxCalories,
    this.coachNotes,
    this.coachId,
    this.coachName,
    this.totalCalories,
    this.totalItems,
    this.completedItems,
    this.isActive = true,
    this.status = 'Active',
    this.approvedAt,
  });

  final String id;
  final String title;
  final String planType; // daily / weekly / custom
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final int? minCalories;
  final int? maxCalories;
  final String? coachNotes;
  final String? coachId;
  final String? coachName;
  final int? totalCalories;
  final int? totalItems;
  final int? completedItems;
  final bool isActive;
  final String status;
  final DateTime? approvedAt;

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPendingAcceptance => status.toLowerCase() == 'pendingacceptance';

  factory CoachMealPlanListItem.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List?) ?? const [];
    final completed = items.where((e) {
      final m = e as Map;
      return m['isCompleted'] == true || m['IsCompleted'] == true;
    }).length;
    return CoachMealPlanListItem(
      id: (j['id'] ?? j['Id']) as String,
      title: (j['title'] ?? j['Title'] ?? '') as String,
      planType: (j['planType'] ?? j['PlanType'] ?? '') as String,
      startDate: _parseDate(j['startDate'] ?? j['StartDate']),
      endDate: _parseDate(j['endDate'] ?? j['EndDate']),
      targetCalories: (j['targetCalories'] ?? j['TargetCalories']) as int?,
      minCalories: (j['minCalories'] ?? j['MinCalories']) as int?,
      maxCalories: (j['maxCalories'] ?? j['MaxCalories']) as int?,
      coachNotes: (j['coachNotes'] ?? j['CoachNotes'])?.toString(),
      coachId: (j['coachId'] ?? j['CoachId'])?.toString(),
      coachName: (j['coachName'] ?? j['CoachName']) as String?,
      totalCalories: (j['totalCalories'] ?? j['TotalCalories']) as int?,
      totalItems: items.length,
      completedItems: completed,
      isActive: (j['isActive'] ?? j['IsActive'] ?? true) as bool,
      status: (j['status'] ?? j['Status'] ?? 'Active').toString(),
      approvedAt: _parseDateTime(j['approvedAt'] ?? j['ApprovedAt']),
    );
  }
}

class CoachMealPlanDetail {
  CoachMealPlanDetail({
    required this.header,
    required this.itemsByMeal,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
  });

  final CoachMealPlanHeader header;
  final Map<String, List<CoachMealPlanItem>> itemsByMeal;
  final int? targetProteinG;
  final int? targetCarbsG;
  final int? targetFatG;

  factory CoachMealPlanDetail.fromJson(Map<String, dynamic> j) {
    final header = CoachMealPlanHeader.fromJson(j);
    final raw = (j['items'] ?? j['Items']) as List? ?? const [];
    final items = raw
        .map(
          (e) =>
              CoachMealPlanItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    final grouped = <String, List<CoachMealPlanItem>>{
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snack': [],
    };
    for (final it in items) {
      final key = it.mealType.toLowerCase();
      grouped.putIfAbsent(key, () => []).add(it);
    }
    return CoachMealPlanDetail(
      header: header,
      itemsByMeal: grouped,
      targetProteinG: (j['targetProteinG'] ?? j['TargetProteinG']) as int?,
      targetCarbsG: (j['targetCarbsG'] ?? j['TargetCarbsG']) as int?,
      targetFatG: (j['targetFatG'] ?? j['TargetFatG']) as int?,
    );
  }
}

class CoachMealPlanHeader {
  CoachMealPlanHeader({
    required this.id,
    required this.title,
    required this.planType,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.targetCalories,
    this.minCalories,
    this.maxCalories,
    this.coachNotes,
    this.coachId,
    this.coachName,
    this.status = 'Active',
    this.approvedAt,
  });

  final String id;
  final String title;
  final String planType;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final int? minCalories;
  final int? maxCalories;
  final String? coachNotes;
  final String? coachId;
  final String? coachName;
  final String status;
  final DateTime? approvedAt;

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPendingAcceptance => status.toLowerCase() == 'pendingacceptance';

  factory CoachMealPlanHeader.fromJson(Map<String, dynamic> j) {
    return CoachMealPlanHeader(
      id: (j['id'] ?? j['Id']) as String,
      title: (j['title'] ?? j['Title'] ?? '') as String,
      planType: (j['planType'] ?? j['PlanType'] ?? '') as String,
      isActive: (j['isActive'] ?? j['IsActive'] ?? true) as bool,
      startDate: _parseDate(j['startDate'] ?? j['StartDate']),
      endDate: _parseDate(j['endDate'] ?? j['EndDate']),
      targetCalories: (j['targetCalories'] ?? j['TargetCalories']) as int?,
      minCalories: (j['minCalories'] ?? j['MinCalories']) as int?,
      maxCalories: (j['maxCalories'] ?? j['MaxCalories']) as int?,
      coachNotes: (j['coachNotes'] ?? j['CoachNotes'])?.toString(),
      coachId: (j['coachId'] ?? j['CoachId'])?.toString(),
      coachName: (j['coachName'] ?? j['CoachName']) as String?,
      status: (j['status'] ?? j['Status'] ?? 'Active').toString(),
      approvedAt: _parseDateTime(j['approvedAt'] ?? j['ApprovedAt']),
    );
  }
}

class CoachMealPlanItem {
  CoachMealPlanItem({
    required this.id,
    required this.mealType,
    required this.displayName,
    this.foodId,
    this.recipeId,
    this.plannedDate,
    this.scheduledTime,
    this.targetCalories = 0,
    this.isCompleted = false,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final String id;
  final String mealType; // breakfast / lunch / dinner / snack
  final String displayName;
  final String? foodId;
  final String? recipeId;
  final DateTime? plannedDate;
  final String? scheduledTime; // "07:30"
  final int targetCalories;
  final bool isCompleted;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  factory CoachMealPlanItem.fromJson(Map<String, dynamic> j) {
    final mealType = (j['mealType'] ?? j['MealType'] ?? 'snack') as String;
    String name = '';
    final foodName = j['foodName'] ?? j['FoodName'];
    final recipeName = j['recipeName'] ?? j['RecipeName'];
    if (foodName is String && foodName.isNotEmpty) {
      name = foodName;
    } else if (recipeName is String && recipeName.isNotEmpty) {
      name = recipeName;
    } else {
      name = (j['name'] ?? j['Name'] ?? 'Món') as String;
    }
    return CoachMealPlanItem(
      id: (j['id'] ?? j['Id']) as String,
      mealType: mealType,
      displayName: name,
      foodId: (j['foodId'] ?? j['FoodId'])?.toString(),
      recipeId: (j['recipeId'] ?? j['RecipeId'])?.toString(),
      plannedDate: _parseDate(j['plannedDate'] ?? j['PlannedDate']),
      scheduledTime: (j['scheduledTime'] ?? j['ScheduledTime'])?.toString(),
      targetCalories: (j['targetCalories'] ?? j['TargetCalories'] ?? 0) as int,
      isCompleted: (j['isCompleted'] ?? j['IsCompleted'] ?? false) as bool,
      proteinG: _num(j['proteinG'] ?? j['ProteinG'])?.toDouble(),
      carbsG: _num(j['carbsG'] ?? j['CarbsG'])?.toDouble(),
      fatG: _num(j['fatG'] ?? j['FatG'])?.toDouble(),
    );
  }
}

/// Convert server JSON to Flutter DateTime (returns null if invalid).
DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

DateTime? _parseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

num? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}
