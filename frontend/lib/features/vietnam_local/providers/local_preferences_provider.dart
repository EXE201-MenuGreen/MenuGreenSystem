import 'package:flutter/foundation.dart';

import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

/// Local Preferences provider — `2.11 Vietnam-first Local Nutrition`.
class LocalPreferencesProvider extends ChangeNotifier {
  LocalPreferencesProvider({LocalPreferencesRepository? repository})
      : _repo = repository ?? LocalPreferencesRepository();

  final LocalPreferencesRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;

  LocalPreferencesProfile? _profile;
  List<LocalRecommendationItem> _budgetAware = const [];
  List<LocalRecommendationItem> _localFriendly = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LocalPreferencesProfile? get profile => _profile;
  List<LocalRecommendationItem> get budgetAware => _budgetAware;
  List<LocalRecommendationItem> get localFriendly => _localFriendly;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.get();
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      _profile = null;
      notifyListeners();
      return;
    }
    _profile = result.data;
    notifyListeners();
  }

  Future<bool> save({
    String? vietnamRegion,
    String? mealContext,
    int? budgetPerMealVnd,
    String? preferredPortionUnits,
    String? eatingPattern,
    String? dislikedFoods,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final payload = <String, dynamic>{
      if (vietnamRegion != null) 'VietnamRegion': vietnamRegion,
      if (mealContext != null) 'MealContext': mealContext,
      if (budgetPerMealVnd != null) 'BudgetPerMealVnd': budgetPerMealVnd,
      if (preferredPortionUnits != null) 'PreferredPortionUnits': preferredPortionUnits,
      if (eatingPattern != null) 'EatingPattern': eatingPattern,
      if (dislikedFoods != null) 'DislikedFoods': dislikedFoods,
    };
    final result = await _repo.upsert(payload);
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _profile = result.data ?? _profile;
    notifyListeners();
    return true;
  }

  Future<void> loadBudgetAware({int? budgetVnd, int? targetCalories, int? top = 10}) async {
    final result = await _repo.getBudgetAware(
      budgetVnd: budgetVnd,
      targetCalories: targetCalories,
      top: top,
    );
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      _budgetAware = const [];
      notifyListeners();
      return;
    }
    _budgetAware = result.data ?? const [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadLocalFriendly({int? targetCalories, int? top = 10}) async {
    final result = await _repo.getLocalFriendly(
      targetCalories: targetCalories,
      top: top,
    );
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      _localFriendly = const [];
      notifyListeners();
      return;
    }
    _localFriendly = result.data ?? const [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendFeedback({
    required String recommendationId,
    required int rating,
    String? comment,
  }) async {
    final result = await _repo.sendFeedback({
      'recommendationId': recommendationId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    return true;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// POST /api/Nutrition/meal-log/vn — ghi meal log VN.
  Future<bool> createVnMealLog(Map<String, dynamic> payload) async {
    final result = await _repo.createVnMealLog(payload);
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// GET /api/Nutrition/meal-log/vn/history
  Future<List<Map<String, dynamic>>> getVnMealLogHistory({int page = 1}) async {
    final result = await _repo.getVnMealLogHistory(page: page);
    if (!result.success) return [];
    return result.data ?? [];
  }

  /// GET /api/Nutrition/discovery/local
  Future<List<Map<String, dynamic>>> discoveryLocal({String? keyword, int? maxPriceVnd}) async {
    final result = await _repo.discoveryLocal(keyword: keyword, maxPriceVnd: maxPriceVnd);
    if (!result.success) return [];
    return result.data ?? [];
  }

  /// GET /api/Nutrition/discovery/local/by-budget
  Future<List<Map<String, dynamic>>> discoveryLocalByBudget({required int maxPriceVnd}) async {
    final result = await _repo.discoveryLocalByBudget(maxPriceVnd: maxPriceVnd);
    if (!result.success) return [];
    return result.data ?? [];
  }
}
