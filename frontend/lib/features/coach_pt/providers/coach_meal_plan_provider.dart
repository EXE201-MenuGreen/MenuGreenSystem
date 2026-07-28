import 'package:flutter/foundation.dart';

import '../models/coach_meal_plan_models.dart';
import '../repositories/coach_meal_plan_repository.dart';

/// State holder for [CoachMealPlanRepository] lists.
///
/// UI subscribes via `context.watch<CoachMealPlanProvider>()`. The current
/// plan being edited (used by [CoachMealPlanDetailScreen]) is held in
/// [selectedPlan]; once you navigate away and the provider is disposed (or
/// [clearSelection] is called), the cache is dropped.
class CoachMealPlanProvider extends ChangeNotifier {
  CoachMealPlanProvider({CoachMealPlanRepository? repository})
    : _repo = repository ?? CoachMealPlanRepository();

  final CoachMealPlanRepository _repo;

  String? _clientId;
  List<CoachMealPlanListItem> _plans = const [];
  bool _loading = false;
  String? _error;

  DateTime? _rangeFrom;
  DateTime? _rangeTo;
  String? _planTypeFilter;

  // Currently-selected (in-flight) plan detail.
  CoachMealPlanDetail? _selectedPlan;
  bool _loadingDetail = false;
  String? _detailError;

  String? get clientId => _clientId;
  List<CoachMealPlanListItem> get plans => _plans;
  bool get isLoading => _loading;
  String? get error => _error;
  DateTime? get rangeFrom => _rangeFrom;
  DateTime? get rangeTo => _rangeTo;
  String? get planTypeFilter => _planTypeFilter;

  CoachMealPlanDetail? get selectedPlan => _selectedPlan;
  bool get isLoadingDetail => _loadingDetail;
  String? get detailError => _detailError;

  /// Switch to a different Gymer and reload.
  Future<void> loadPlansForClient(
    String clientId, {
    DateTime? from,
    DateTime? to,
    String? planType,
  }) async {
    _clientId = clientId;
    _rangeFrom = from;
    _rangeTo = to;
    _planTypeFilter = planType;
    await _refresh();
  }

  /// Reload with currently-set filters.
  Future<void> _refresh() async {
    final clientId = _clientId;
    if (clientId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _plans = await _repo.listClientMealPlans(
        clientId,
        from: _rangeFrom,
        to: _rangeTo,
        planType: _planTypeFilter,
      );
    } catch (e) {
      _error = e.toString();
      _plans = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _refresh();

  Future<void> loadPlanDetail(String planId) async {
    final clientId = _clientId;
    if (clientId == null) return;
    _loadingDetail = true;
    _detailError = null;
    notifyListeners();
    try {
      _selectedPlan = await _repo.getClientMealPlanDetail(clientId, planId);
    } catch (e) {
      _detailError = e.toString();
      _selectedPlan = null;
    } finally {
      _loadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createPlan(ClientMealPlanPayload payload) async {
    final clientId = _clientId;
    if (clientId == null) return false;
    try {
      final created = await _repo.createClientMealPlan(clientId, payload);
      _selectedPlan = created;
      notifyListeners();
      await _refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlan(String planId, ClientMealPlanPayload payload) async {
    final clientId = _clientId;
    if (clientId == null) return false;
    try {
      final updated = await _repo.updateClientMealPlan(
        clientId,
        planId,
        payload,
      );
      _selectedPlan = updated;
      notifyListeners();
      // Refresh list summary (target/date/title may have changed).
      await _refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Submit / approve the plan and notify the Gymer.
  Future<bool> submitPlan(
    String planId, {
    String? notes,
    int? minCalories,
    int? maxCalories,
  }) async {
    final clientId = _clientId;
    if (clientId == null) return false;
    try {
      final submitted = await _repo.submitClientMealPlan(
        clientId,
        planId,
        notes: notes,
        minCalories: minCalories,
        maxCalories: maxCalories,
      );
      _selectedPlan = submitted;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAndSubmitPlan(
    ClientMealPlanPayload payload, {
    String? notes,
    int? minCalories,
    int? maxCalories,
  }) async {
    final clientId = _clientId;
    if (clientId == null) return false;
    try {
      final created = await _repo.createClientMealPlan(clientId, payload);
      final submitted = await _repo.submitClientMealPlan(
        clientId,
        created.header.id,
        notes: notes,
        minCalories: minCalories,
        maxCalories: maxCalories,
      );
      _selectedPlan = submitted;
      notifyListeners();
      await _refresh();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      await _refresh();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadSuggestions({
    required DateTime date,
    required int targetCalories,
    int? minCalories,
    int? maxCalories,
    int top = 20,
  }) async {
    final clientId = _clientId;
    if (clientId == null) return const [];
    return _repo.getClientSuggestions(
      clientId,
      date: date,
      targetCalories: targetCalories,
      minCalories: minCalories,
      maxCalories: maxCalories,
      top: top,
    );
  }

  Future<Map<String, dynamic>?> loadClientGymConfig(DateTime date) async {
    final clientId = _clientId;
    if (clientId == null) return null;
    return _repo.getClientGymConfig(clientId, date);
  }

  Future<bool> deletePlan(String planId) async {
    final clientId = _clientId;
    if (clientId == null) return false;
    try {
      await _repo.deleteClientMealPlan(clientId, planId);
      if (_selectedPlan?.header.id == planId) _selectedPlan = null;
      notifyListeners();
      await _refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setFilters({DateTime? from, DateTime? to, String? planType}) {
    _rangeFrom = from;
    _rangeTo = to;
    _planTypeFilter = planType;
    _refresh();
  }

  void clearSelection() {
    _selectedPlan = null;
    _detailError = null;
    notifyListeners();
  }
}
