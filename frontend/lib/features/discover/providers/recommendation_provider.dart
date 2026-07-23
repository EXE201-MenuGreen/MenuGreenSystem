import 'package:flutter/foundation.dart';

import '../models/food_models.dart';
import '../repositories/recommendation_repository.dart';

/// State management cho Recommendation workflow
class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({RecommendationRepository? repository})
      : _repository = repository ?? RecommendationRepository();

  final RecommendationRepository _repository;

  // =========================================================================
  // STATES
  // =========================================================================

  // Generate states
  RecommendationGenerateResponse? _currentRecommendation;
  WeeklyPlanResponse? _weeklyPlan;
  BudgetAwareResponse? _budgetPlan;
  List<RecommendationItem> _calorieRecommendations = [];
  List<RecommendationItem> _lunchRecommendations = [];
  List<RecommendationItem> _ecoRecommendations = [];

  // History & Detail
  List<RecommendationHistoryItem> _history = [];
  RecommendationDetail? _currentDetail;

  // Feedback & Explain
  FeedbackSummary? _feedbackSummary;
  String? _explanation;

  // Scores
  RecommendationScore? _currentScore;

  // UI States
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isLoadingHistory = false;
  String? _error;
  
  // Pagination states
  int _historyPage = 1;
  bool _hasMoreHistory = true;
  static const int _pageSize = 10;

  // =========================================================================
  // GETTERS
  // =========================================================================

  RecommendationGenerateResponse? get currentRecommendation => _currentRecommendation;
  WeeklyPlanResponse? get weeklyPlan => _weeklyPlan;
  BudgetAwareResponse? get budgetPlan => _budgetPlan;
  List<RecommendationItem> get calorieRecommendations => _calorieRecommendations;
  List<RecommendationItem> get lunchRecommendations => _lunchRecommendations;
  List<RecommendationItem> get ecoRecommendations => _ecoRecommendations;
  List<RecommendationHistoryItem> get history => _history;
  RecommendationDetail? get currentDetail => _currentDetail;
  FeedbackSummary? get feedbackSummary => _feedbackSummary;
  String? get explanation => _explanation;
  RecommendationScore? get currentScore => _currentScore;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  bool get hasMoreHistory => _hasMoreHistory;

  // =========================================================================
  // GENERATE METHODS
  // =========================================================================

  Future<void> generateRecommendation({
    String? mealType,
    int? targetCalories,
    int maxResults = 10,
    bool excludeUserAllergies = false,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final request = RecommendationGenerateRequest(
        mealType: mealType,
        targetCalories: targetCalories,
        maxResults: maxResults,
        excludeUserAllergies: excludeUserAllergies,
      );
      _currentRecommendation = await _repository.generateRecommendation(request);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> generateSafeRecommendation({
    String? mealType,
    int? targetCalories,
    int maxResults = 10,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final request = SafeRecommendationRequest(
        mealType: mealType,
        targetCalories: targetCalories,
        maxResults: maxResults,
      );
      _currentRecommendation = await _repository.generateSafeRecommendation(request);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> generateWeeklyPlan({
    required DateTime startDate,
    required DateTime endDate,
    int? dailyTargetCalories,
    bool excludeUserAllergies = false,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final request = WeeklyPlanRequest(
        startDate: startDate,
        endDate: endDate,
        dailyTargetCalories: dailyTargetCalories,
        excludeUserAllergies: excludeUserAllergies,
      );
      _weeklyPlan = await _repository.generateWeeklyPlan(request);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> generateBudgetAware({
    String? mealType,
    int? maxBudgetVnd,
    int? targetCalories,
    int maxResults = 10,
    bool excludeUserAllergies = false,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final request = BudgetAwareRequest(
        mealType: mealType,
        maxBudgetVnd: maxBudgetVnd,
        targetCalories: targetCalories,
        maxResults: maxResults,
        excludeUserAllergies: excludeUserAllergies,
      );
      _budgetPlan = await _repository.generateBudgetAware(request);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // TODAY RECOMMENDATIONS (Phase 1 — QuickRecommendationCard)
  // =========================================================================

  RecommendationItem? _todayBreakfast;
  RecommendationItem? _todayLunch;
  RecommendationItem? _todayDinner;
  bool _isLoadingToday = false;
  String? _todayError;

  RecommendationItem? get todayBreakfast => _todayBreakfast;
  RecommendationItem? get todayLunch => _todayLunch;
  RecommendationItem? get todayDinner => _todayDinner;
  bool get isLoadingToday => _isLoadingToday;
  String? get todayError => _todayError;

  Future<void> loadTodayRecommendations() async {
    _isLoadingToday = true;
    _todayError = null;
    _todayBreakfast = null;
    _todayLunch = null;
    _todayDinner = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.generateSafeRecommendation(SafeRecommendationRequest(mealType: 'breakfast', maxResults: 1)),
        _repository.generateSafeRecommendation(SafeRecommendationRequest(mealType: 'lunch', maxResults: 1)),
        _repository.generateSafeRecommendation(SafeRecommendationRequest(mealType: 'dinner', maxResults: 1)),
      ]);

      _todayBreakfast = results[0]?.items.firstOrNull;
      _todayLunch = results[1]?.items.firstOrNull;
      _todayDinner = results[2]?.items.firstOrNull;

      _todayError = null;
    } catch (e) {
      _todayError = e.toString();
    } finally {
      _isLoadingToday = false;
      notifyListeners();
    }
  }

  void clearTodayRecommendations() {
    _todayBreakfast = null;
    _todayLunch = null;
    _todayDinner = null;
    _todayError = null;
    notifyListeners();
  }

  // =========================================================================
  // LEGACY METHODS (backward compatibility)
  // =========================================================================

  Future<void> loadCaloriesRecommendations({
    int? targetCalories,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _calorieRecommendations = await _repository.recommendCalories(
        targetCalories: targetCalories,
        top: top,
        excludeUserAllergies: excludeUserAllergies,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLunchRecommendations({
    int? targetCalories,
    int? budgetVnd,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lunchRecommendations = await _repository.recommendLunch(
        targetCalories: targetCalories,
        budgetVnd: budgetVnd,
        top: top,
        excludeUserAllergies: excludeUserAllergies,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEcoRecommendations({
    int? budgetVnd,
    int? limitMinutes,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ecoRecommendations = await _repository.recommendEco(
        budgetVnd: budgetVnd,
        limitMinutes: limitMinutes,
        top: top,
        excludeUserAllergies: excludeUserAllergies,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // HISTORY & DETAIL METHODS
  // =========================================================================

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    _error = null;
    _historyPage = 1;
    _hasMoreHistory = true;
    notifyListeners();

    try {
      _history = await _repository.getHistory(page: _historyPage, pageSize: _pageSize);
      _hasMoreHistory = _history.length >= _pageSize;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory() async {
    if (_isLoadingHistory || !_hasMoreHistory) return;
    
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _historyPage++;
      final moreItems = await _repository.getHistory(page: _historyPage, pageSize: _pageSize);
      _history.addAll(moreItems);
      _hasMoreHistory = moreItems.length >= _pageSize;
    } catch (e) {
      _historyPage--; // Revert on error
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentDetail = await _repository.getById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // PREVIEW METHOD
  // =========================================================================

  Future<RecommendationGenerateResponse?> preview({
    String? mealType,
    int? targetCalories,
    int? maxBudgetVnd,
    bool excludeUserAllergies = false,
    List<String> preferenceTags = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = RecommendationPreviewRequest(
        mealType: mealType,
        targetCalories: targetCalories,
        maxBudgetVnd: maxBudgetVnd,
        excludeUserAllergies: excludeUserAllergies,
        preferenceTags: preferenceTags,
      );
      final preview_ = await _repository.preview(request);
      _error = null;
      return preview_;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // FEEDBACK METHODS
  // =========================================================================

  Future<bool> submitFeedback({
    required String recommendationId,
    required bool isLiked,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final feedback = RecommendationFeedback(
        id: '',
        recommendationId: recommendationId,
        isLiked: isLiked,
        comment: comment,
      );
      final success = await _repository.submitFeedback(feedback);

      // Update local state if detail matches
      if (_currentDetail?.id == recommendationId) {
        _currentDetail = _currentDetail!;
      }

      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFeedback({
    required String id,
    required String recommendationId,
    required bool isLiked,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final feedback = RecommendationFeedback(
        id: id,
        recommendationId: recommendationId,
        isLiked: isLiked,
        comment: comment,
      );
      final success = await _repository.updateFeedback(id, feedback);
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeedbackSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feedbackSummary = await _repository.getFeedbackSummary();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // EXPLAIN METHOD
  // =========================================================================

  Future<void> explain(String id) async {
    _isLoading = true;
    _error = null;
    _explanation = null;
    notifyListeners();

    try {
      _explanation = await _repository.explain(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // SCORES METHOD
  // =========================================================================

  Future<void> loadScores({
    String? recipeId,
    int? calories,
    bool? excludeAllergies,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentScore = await _repository.getScores(
        recipeId: recipeId,
        calories: calories,
        excludeAllergies: excludeAllergies,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // RETRAIN METHOD
  // =========================================================================

  Future<bool> retrain({
    bool useHistory = true,
    bool useExplicit = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.retrain(
        useHistory: useHistory,
        useExplicit: useExplicit,
      );
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // SMART SCHEDULE METHOD
  // =========================================================================

  Future<dynamic> buildSmartSchedule({
    required DateTime expectedMealTime,
    required int cookingTimeMinutes,
    int limit = 5,
    int bufferMinutes = 5,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.buildSmartSchedule(
        expectedMealTime: expectedMealTime,
        cookingTimeMinutes: cookingTimeMinutes,
        limit: limit,
        bufferMinutes: bufferMinutes,
      );
      _error = null;
      return response;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentRecommendation() {
    _currentRecommendation = null;
    _explanation = null;
    _currentScore = null;
    notifyListeners();
  }

  void clearWeeklyPlan() {
    _weeklyPlan = null;
    notifyListeners();
  }

  void clearBudgetPlan() {
    _budgetPlan = null;
    notifyListeners();
  }

  void reset() {
    _currentRecommendation = null;
    _weeklyPlan = null;
    _budgetPlan = null;
    _calorieRecommendations = [];
    _lunchRecommendations = [];
    _ecoRecommendations = [];
    _history = [];
    _currentDetail = null;
    _feedbackSummary = null;
    _explanation = null;
    _currentScore = null;
    _todayBreakfast = null;
    _todayLunch = null;
    _todayDinner = null;
    _todayError = null;
    _isLoading = false;
    _isGenerating = false;
    _isLoadingHistory = false;
    _error = null;
    notifyListeners();
  }
}
