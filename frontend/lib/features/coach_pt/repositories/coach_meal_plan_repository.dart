import '../../advanced/repositories/advanced_repository.dart';
import '../models/coach_meal_plan_models.dart';

/// Helper functions for parsing JSON
int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return double.tryParse(v)?.round() ?? 0;
  return 0;
}

num? _parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// Nutrition summary for a single day (used by PT to track client eating).
class ClientDayNutrition {
  final DateTime date;
  final int plannedCalories;
  final int actualCalories;
  final int plannedProtein;
  final int actualProtein;
  final int plannedCarbs;
  final int actualCarbs;
  final int plannedFat;
  final int actualFat;
  final List<ClientMealLogItem> logs;

  ClientDayNutrition({
    required this.date,
    required this.plannedCalories,
    required this.actualCalories,
    required this.plannedProtein,
    required this.actualProtein,
    required this.plannedCarbs,
    required this.actualCarbs,
    required this.plannedFat,
    required this.actualFat,
    required this.logs,
  });

  factory ClientDayNutrition.fromJson(Map<String, dynamic> j) {
    return ClientDayNutrition(
      date: DateTime.parse(j['date'] ?? j['Date']),
      plannedCalories: _parseInt(
        j['plannedCalories'] ??
            j['PlannedCalories'] ??
            j['targetCalories'] ??
            j['TargetCalories'],
      ),
      actualCalories: _parseInt(j['actualCalories'] ?? j['ActualCalories']),
      plannedProtein: _parseInt(
        j['plannedProtein'] ??
            j['PlannedProtein'] ??
            j['targetProtein'] ??
            j['TargetProtein'],
      ),
      actualProtein: _parseInt(j['actualProtein'] ?? j['ActualProtein']),
      plannedCarbs: _parseInt(
        j['plannedCarbs'] ??
            j['PlannedCarbs'] ??
            j['targetCarbs'] ??
            j['TargetCarbs'],
      ),
      actualCarbs: _parseInt(j['actualCarbs'] ?? j['ActualCarbs']),
      plannedFat: _parseInt(
        j['plannedFat'] ?? j['PlannedFat'] ?? j['targetFat'] ?? j['TargetFat'],
      ),
      actualFat: _parseInt(j['actualFat'] ?? j['ActualFat']),
      logs: (j['logs'] ?? j['Logs'] ?? [])
          .map<ClientMealLogItem>(
            (e) => ClientMealLogItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

/// A single meal log entry for the nutrition summary.
class ClientMealLogItem {
  final String id;
  final String? mealPlanItemId;
  final String? foodId;
  final String? recipeId;
  final String? foodName;
  final String? recipeName;
  final String? customName;
  final String? serverDisplayName;
  final String mealType;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime loggedAt;

  ClientMealLogItem({
    required this.id,
    this.mealPlanItemId,
    this.foodId,
    this.recipeId,
    this.foodName,
    this.recipeName,
    this.customName,
    this.serverDisplayName,
    required this.mealType,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.loggedAt,
  });

  factory ClientMealLogItem.fromJson(Map<String, dynamic> j) {
    return ClientMealLogItem(
      id: (j['id'] ?? j['Id']).toString(),
      mealPlanItemId: (j['mealPlanItemId'] ?? j['MealPlanItemId'])?.toString(),
      foodId: (j['foodId'] ?? j['FoodId'])?.toString(),
      recipeId: (j['recipeId'] ?? j['RecipeId'])?.toString(),
      foodName: (j['foodName'] ?? j['FoodName'])?.toString(),
      recipeName:
          (j['recipeName'] ??
                  j['RecipeName'] ??
                  j['recipeTitle'] ??
                  j['RecipeTitle'])
              ?.toString(),
      customName: (j['customName'] ?? j['CustomName'])?.toString(),
      serverDisplayName: (j['displayName'] ?? j['DisplayName'])?.toString(),
      mealType: (j['mealType'] ?? j['MealType'] ?? 'snack').toString(),
      calories: _parseInt(
        j['calories'] ??
            j['Calories'] ??
            j['caloriesKcal'] ??
            j['CaloriesKcal'],
      ),
      proteinG: _parseNum(j['proteinG'] ?? j['ProteinG'])?.toDouble() ?? 0,
      carbsG: _parseNum(j['carbsG'] ?? j['CarbsG'])?.toDouble() ?? 0,
      fatG: _parseNum(j['fatG'] ?? j['FatG'])?.toDouble() ?? 0,
      loggedAt: DateTime.parse(
        j['loggedAt'] ??
            j['LoggedAt'] ??
            j['loggedAtDate'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  String get displayName =>
      (serverDisplayName ?? customName ?? foodName ?? recipeName ?? 'Món ăn')
          .trim();
  bool get isLinkedToPlan =>
      mealPlanItemId != null && mealPlanItemId!.isNotEmpty;
}

/// Thin wrapper around [AdvancedRepository] that exposes Coach-side
/// meal-plan operations and returns parsed [CoachMealPlanListItem] /
/// [CoachMealPlanDetail] models.
///
/// Kept separate from [AdvancedRepository] so the UI layer can:
/// * depend only on the [coach_pt] package,
/// * swap implementations (mock / fake) in tests,
/// * centralize JSON parsing here instead of in widgets.
class CoachMealPlanRepository {
  CoachMealPlanRepository({AdvancedRepository? advanced})
    : _advanced = advanced ?? AdvancedRepository();

  final AdvancedRepository _advanced;

  /// Fetch nutrition summary (planned vs actual) for a client over N days.
  Future<List<ClientDayNutrition>> getClientNutritionSummary(
    String clientId, {
    DateTime? from,
    DateTime? to,
    int days = 7,
  }) async {
    final raw = await _advanced.clientNutrition(
      clientId,
      days: days,
      from: from,
      to: to,
    );

    // Filter by date range if provided
    var filtered = raw;
    if (from != null && to != null) {
      filtered = raw.where((j) {
        final dateStr = j['date'] ?? j['Date'];
        if (dateStr == null) return false;
        try {
          final date = DateTime.parse(dateStr.toString());
          return !date.isBefore(from) && !date.isAfter(to);
        } catch (_) {
          return false;
        }
      }).toList();
    }

    return filtered.map((j) => ClientDayNutrition.fromJson(j)).toList();
  }

  /// List plans of a Gymer, with date-range and plan-type filters.
  Future<List<CoachMealPlanListItem>> listClientMealPlans(
    String clientId, {
    DateTime? from,
    DateTime? to,
    String? planType,
  }) async {
    final raw = await _advanced.clientMealPlans(
      clientId,
      from: from,
      to: to,
      planType: planType,
    );
    return raw.map(CoachMealPlanListItem.fromJson).toList();
  }

  /// Fetch one plan detail.
  Future<CoachMealPlanDetail> getClientMealPlanDetail(
    String clientId,
    String planId,
  ) async {
    final raw = await _advanced.clientMealPlanDetail(clientId, planId);
    return CoachMealPlanDetail.fromJson(raw);
  }

  /// Create a new plan on behalf of a Gymer.
  /// [body] follows [ClientMealPlanPayload.toJson] shape.
  Future<CoachMealPlanDetail> createClientMealPlan(
    String clientId,
    ClientMealPlanPayload body,
  ) async {
    final raw = await _advanced.createClientMealPlan(clientId, body.toJson());
    return CoachMealPlanDetail.fromJson(raw);
  }

  /// Update an existing plan (replace items / dates / target).
  Future<CoachMealPlanDetail> updateClientMealPlan(
    String clientId,
    String planId,
    ClientMealPlanPayload body,
  ) async {
    final raw = await _advanced.updateClientMealPlan(
      clientId,
      planId,
      body.toJson(),
    );
    return CoachMealPlanDetail.fromJson(raw);
  }

  /// Submit / approve and notify the Gymer.
  Future<CoachMealPlanDetail> submitClientMealPlan(
    String clientId,
    String planId, {
    String? notes,
    int? minCalories,
    int? maxCalories,
  }) async {
    final raw = await _advanced.submitClientMealPlan(
      clientId,
      planId,
      notes: notes,
      minCalories: minCalories,
      maxCalories: maxCalories,
    );
    return CoachMealPlanDetail.fromJson(raw);
  }

  Future<List<Map<String, dynamic>>> getClientSuggestions(
    String clientId, {
    required DateTime date,
    required int targetCalories,
    int? minCalories,
    int? maxCalories,
    double? minProteinG,
    double? maxProteinG,
    int top = 20,
  }) {
    return _advanced.clientSuggestions(
      clientId,
      date: date,
      targetCalories: targetCalories,
      minCalories: minCalories,
      maxCalories: maxCalories,
      minProteinG: minProteinG,
      maxProteinG: maxProteinG,
      top: top,
    );
  }

  Future<Map<String, dynamic>> getClientGymConfig(
    String clientId,
    DateTime date,
  ) {
    return _advanced.clientGymConfig(clientId, date);
  }

  /// Soft-delete (deactivate) a plan.
  Future<void> deleteClientMealPlan(String clientId, String planId) =>
      _advanced.deleteClientMealPlan(clientId, planId);
}

/// Payload sent to [CoachMealPlanRepository.createClientMealPlan] /
/// [CoachMealPlanRepository.updateClientMealPlan].
///
/// Items list mirrors the backend [MealPlanItemUpsertRequest] shape.
class ClientMealPlanPayload {
  ClientMealPlanPayload({
    required this.title,
    required this.planType,
    this.startDate,
    this.endDate,
    this.targetCalories,
    this.minCalories,
    this.maxCalories,
    this.coachNotes,
    this.isActive = true,
    this.items = const [],
  });

  final String title;
  final String planType; // daily / weekly / custom
  final DateTime? startDate;
  final DateTime? endDate;
  final int? targetCalories;
  final int? minCalories;
  final int? maxCalories;
  final String? coachNotes;
  final bool isActive;
  final List<ClientMealPlanItemPayload> items;

  Map<String, dynamic> toJson() => {
    'title': title,
    'planType': planType,
    if (startDate != null) 'startDate': _date(startDate!),
    if (endDate != null) 'endDate': _date(endDate!),
    if (targetCalories != null) 'targetCalories': targetCalories,
    if (minCalories != null) 'minCalories': minCalories,
    if (maxCalories != null) 'maxCalories': maxCalories,
    if (coachNotes != null && coachNotes!.trim().isNotEmpty)
      'coachNotes': coachNotes!.trim(),
    'isActive': isActive,
    if (items.isNotEmpty) 'items': items.map((i) => i.toJson()).toList(),
  };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class ClientMealPlanItemPayload {
  ClientMealPlanItemPayload({
    this.id,
    required this.mealType,
    this.foodId,
    this.recipeId,
    this.plannedDate,
    this.scheduledTime,
    this.targetCalories,
    this.quantityG,
  });

  /// Null when adding a new item; required when updating an existing one.
  final String? id;
  final String mealType; // breakfast / lunch / dinner / snack
  final String? foodId;
  final String? recipeId;
  final DateTime? plannedDate;
  final String? scheduledTime; // "HH:mm"
  final int? targetCalories;
  final double? quantityG;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'mealType': mealType.toLowerCase(),
    if (foodId != null) 'foodId': foodId,
    if (recipeId != null) 'recipeId': recipeId,
    if (plannedDate != null)
      'plannedDate':
          '${plannedDate!.year.toString().padLeft(4, '0')}-'
          '${plannedDate!.month.toString().padLeft(2, '0')}-'
          '${plannedDate!.day.toString().padLeft(2, '0')}',
    if (scheduledTime != null) 'scheduledTime': scheduledTime,
    if (targetCalories != null) 'targetCalories': targetCalories,
    if (quantityG != null) 'quantityG': quantityG,
  };
}
