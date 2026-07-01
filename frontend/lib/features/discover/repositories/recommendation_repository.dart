import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/food_models.dart';

class RecommendationRepository {
  RecommendationRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  String _query(Map<String, String> params) {
    if (params.isEmpty) return '';
    return '?${params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
  }

  // =========================================================================
  // LEGACY METHODS (kept for backward compatibility)
  // =========================================================================

  Future<List<RecommendationItem>> recommendCalories({
    int? targetCalories,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    final params = <String, String>{
      'top': '$top',
      'excludeUserAllergies': excludeUserAllergies.toString(),
      if (targetCalories != null) 'targetCalories': '$targetCalories',
    };
    return _fetchList(ApiEndpoints.recommendationCalories + _query(params));
  }

  Future<List<RecommendationItem>> recommendLunch({
    int? targetCalories,
    int? budgetVnd,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    final params = <String, String>{
      'top': '$top',
      'excludeUserAllergies': excludeUserAllergies.toString(),
      if (targetCalories != null) 'targetCalories': '$targetCalories',
      if (budgetVnd != null) 'budgetVnd': '$budgetVnd',
    };
    return _fetchList(ApiEndpoints.recommendationLunch + _query(params));
  }

  Future<List<RecommendationItem>> recommendEco({
    int? budgetVnd,
    int? limitMinutes,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    final params = <String, String>{
      'top': '$top',
      'excludeUserAllergies': excludeUserAllergies.toString(),
      if (budgetVnd != null) 'budgetVnd': '$budgetVnd',
      if (limitMinutes != null) 'limitMinutes': '$limitMinutes',
    };
    return _fetchList(ApiEndpoints.recommendationEco + _query(params));
  }

  Future<DailyMenuPlan?> recommendDailyMenu({
    int? targetCalories,
    bool excludeUserAllergies = true,
  }) async {
    try {
      final params = <String, String>{
        'excludeUserAllergies': excludeUserAllergies.toString(),
        if (targetCalories != null) 'targetCalories': '$targetCalories',
      };
      final response = await _api.get(ApiEndpoints.recommendationDailyMenu + _query(params));
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return DailyMenuPlan.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // GENERATE METHODS (Extended)
  // =========================================================================

  Future<RecommendationGenerateResponse?> generateRecommendation(
    RecommendationGenerateRequest request,
  ) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationGenerate,
        request.toJson(),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return RecommendationGenerateResponse.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<RecommendationGenerateResponse?> generateSafeRecommendation(
    SafeRecommendationRequest request,
  ) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationGenerateSafe,
        request.toJson(),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return RecommendationGenerateResponse.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<WeeklyPlanResponse?> generateWeeklyPlan(
    WeeklyPlanRequest request,
  ) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationGenerateWeeklyPlan,
        request.toJson(),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return WeeklyPlanResponse.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<BudgetAwareResponse?> generateBudgetAware(
    BudgetAwareRequest request,
  ) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationGenerateBudgetAware,
        request.toJson(),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return BudgetAwareResponse.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // HISTORY & DETAIL METHODS
  // =========================================================================

  Future<List<RecommendationHistoryItem>> getHistory() async {
    try {
      final response = await _api.get(ApiEndpoints.recommendationHistory);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RecommendationHistoryItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<RecommendationDetail?> getById(String id) async {
    try {
      final response = await _api.get(ApiEndpoints.recommendationById(id));
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return RecommendationDetail.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // PREVIEW METHOD
  // =========================================================================

  Future<RecommendationGenerateResponse?> preview(
    RecommendationPreviewRequest request,
  ) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationPreview,
        request.toJson(),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return RecommendationGenerateResponse.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // FEEDBACK METHODS
  // =========================================================================

  Future<bool> submitFeedback(RecommendationFeedback feedback) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationFeedback,
        feedback.toJson(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateFeedback(String id, RecommendationFeedback feedback) async {
    try {
      final response = await _api.putJson(
        ApiEndpoints.recommendationUpdateFeedback(id),
        feedback.toJson(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<FeedbackSummary?> getFeedbackSummary() async {
    try {
      final response = await _api.get(ApiEndpoints.recommendationFeedbackSummary);
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return FeedbackSummary.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // EXPLAIN METHOD
  // =========================================================================

  Future<String?> explain(String id) async {
    try {
      final response = await _api.get(ApiEndpoints.recommendationExplain(id));
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['explanation']?.toString() ??
            decoded['Explanation']?.toString() ??
            decoded['message']?.toString() ??
            decoded['Message']?.toString();
      }
      return decoded.toString();
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // SCORES METHOD
  // =========================================================================

  Future<RecommendationScore?> getScores({
    String? recipeId,
    int? calories,
    bool? excludeAllergies,
  }) async {
    try {
      final params = <String, String>{
        if (recipeId != null) 'recipeId': recipeId,
        if (calories != null) 'calories': '$calories',
        if (excludeAllergies != null) 'excludeAllergies': excludeAllergies.toString(),
      };
      final response = await _api.get(
        ApiEndpoints.recommendationScores + _query(params),
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return RecommendationScore.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // RETRAIN METHOD
  // =========================================================================

  Future<bool> retrain({
    bool useHistory = true,
    bool useExplicit = true,
  }) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationRetrain,
        {
          'useHistory': useHistory,
          'useExplicit': useExplicit,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
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
    try {
      final response = await _api.postJson(
        ApiEndpoints.recommendationSmartSchedule,
        {
          'expectedMealTime': expectedMealTime.toIso8601String(),
          'cookingTimeMinutes': cookingTimeMinutes,
          'limit': limit,
          'bufferMinutes': bufferMinutes,
        },
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  Future<List<RecommendationItem>> _fetchList(String url) async {
    try {
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RecommendationItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
