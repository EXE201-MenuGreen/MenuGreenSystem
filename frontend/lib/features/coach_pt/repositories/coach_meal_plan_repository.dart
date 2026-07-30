import '../../advanced/repositories/advanced_repository.dart';
import '../models/coach_meal_plan_models.dart';

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
    int top = 20,
  }) {
    return _advanced.clientSuggestions(
      clientId,
      date: date,
      targetCalories: targetCalories,
      minCalories: minCalories,
      maxCalories: maxCalories,
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
  });

  /// Null when adding a new item; required when updating an existing one.
  final String? id;
  final String mealType; // breakfast / lunch / dinner / snack
  final String? foodId;
  final String? recipeId;
  final DateTime? plannedDate;
  final String? scheduledTime; // "HH:mm"
  final int? targetCalories;

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
  };
}
