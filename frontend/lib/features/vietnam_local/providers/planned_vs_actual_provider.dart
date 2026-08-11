import 'package:flutter/foundation.dart';

import '../../meal_plan/models/meal_plan_models.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

/// Planned vs Actual provider — `2.17 Planned vs Actual Insights`.
class PlannedVsActualProvider extends ChangeNotifier {
  PlannedVsActualProvider({
    PlannedVsActualRepository? repository,
    MealPlanRepository? mealPlanRepository,
    NutritionTrackingRepository? nutritionTrackingRepository,
  }) : _repo = repository ?? PlannedVsActualRepository(),
       _mealPlanRepo = mealPlanRepository ?? MealPlanRepository(),
       _nutritionRepo =
           nutritionTrackingRepository ?? NutritionTrackingRepository();

  final PlannedVsActualRepository _repo;
  final MealPlanRepository _mealPlanRepo;
  final NutritionTrackingRepository _nutritionRepo;

  bool _isLoading = false;
  String? _errorMessage;

  PlannedVsActualSummary? _summary;
  AdherenceScore? _adherence;
  DriftAnalysis? _drift;
  PlannedVsActualRecommendations? _recommendations;
  Map<String, dynamic>? _lastRecalibration;
  UserMealPlan? _dailyPlan;
  MealDaySummary? _dailySummary;

  DateTime _from = _dateOnly(DateTime.now());
  DateTime _to = _dateOnly(DateTime.now());

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PlannedVsActualSummary? get summary => _summary;
  AdherenceScore? get adherence => _adherence;
  DriftAnalysis? get drift => _drift;
  PlannedVsActualRecommendations? get recommendations => _recommendations;
  Map<String, dynamic>? get lastRecalibration => _lastRecalibration;
  UserMealPlan? get dailyPlan => _dailyPlan;
  MealDaySummary? get dailySummary => _dailySummary;
  DateTime get selectedDate => _from;
  DateTime get from => _from;
  DateTime get to => _to;

  void setRange(DateTime from, DateTime to) {
    if (from.isAfter(to)) {
      final tmp = from;
      from = to;
      to = tmp;
    }
    _from = from;
    _to = to;
    notifyListeners();
  }

  void setDate(DateTime date) {
    final normalized = _dateOnly(date);
    if (_from == normalized && _to == normalized) return;
    _from = normalized;
    _to = normalized;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final requestedDate = _from;
    PlannedVsActualSummary? summaryData;
    AdherenceScore? adherenceData;
    DriftAnalysis? driftData;
    UserMealPlan? planData;
    MealDaySummary? dailyData;
    final errors = <String>[];

    // Load the canonical daily log first. Besides powering the meal list, the
    // backend uses this call to repair legacy plan-completion logs whose
    // serving calories were multiplied by grams. Analytics fetched below then
    // sees the corrected values in the same refresh.
    try {
      dailyData = await _nutritionRepo.getDailySummary(requestedDate);
    } catch (_) {
      errors.add('Không tải được danh sách món đã ăn trong ngày.');
    }

    await Future.wait<void>([
      () async {
        final result = await _repo.getSummary(
          from: requestedDate,
          to: requestedDate,
        );
        if (result.success) {
          summaryData = result.data;
        } else {
          errors.add(result.translatedMessage);
        }
      }(),
      () async {
        final result = await _repo.getAdherenceScore(
          from: requestedDate,
          to: requestedDate,
        );
        if (result.success) adherenceData = result.data;
      }(),
      () async {
        final result = await _repo.getDriftAnalysis(
          from: requestedDate,
          to: requestedDate,
        );
        if (result.success) driftData = result.data;
      }(),
      () async {
        planData = await _mealPlanRepo.getByDate(requestedDate);
      }(),
    ]);

    // Ignore an older request if the user changed date while it was loading.
    if (_from != requestedDate) return;
    _summary = summaryData;
    _adherence = adherenceData;
    _drift = driftData;
    _dailyPlan = planData;
    _dailySummary = dailyData;
    _errorMessage = errors.isEmpty ? null : errors.first;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> recalibrate() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.recalibrate();
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _lastRecalibration = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : null;
    notifyListeners();
    return true;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<ApiResult<dynamic>> getMonthlyReport({
    int? month,
    int? year,
    String format = 'json',
  }) async {
    return _repo.getMonthlyReport(month: month, year: year, format: format);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
