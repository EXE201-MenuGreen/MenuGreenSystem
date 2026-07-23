import 'dart:convert';

import '../../../core/middleware/query_middleware.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/food_models.dart';

class RecommendationRepository {
  RecommendationRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _decodeObject(String body, String operation) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw FormatException('$operation trả về dữ liệu không đúng định dạng.');
  }

  String _responseError(dynamic response, String operation) {
    if (response.body is String && (response.body as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body as String);
        if (decoded is Map) {
          final message = decoded['message'] ?? decoded['Message'] ?? decoded['error'] ?? decoded['Error'];
          if (message != null && message.toString().trim().isNotEmpty) {
            return message.toString();
          }
        }
      } on FormatException {
        // Use the stable fallback below when the error body is not JSON.
      }
    }
    return '$operation thất bại (HTTP ${response.statusCode}).';
  }

  Map<String, dynamic> _requireObject(dynamic response, String operation) {
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw StateError(_responseError(response, operation));
    }
    return _decodeObject(response.body, operation);
  }

  String _query(Map<String, String> params) {
    if (params.isEmpty) return '';
    final query = QueryMiddleware.buildQuery(params);
    return query.isEmpty ? '' : '?$query';
  }

  // =========================================================================
  // LEGACY METHODS (kept for backward compatibility)
  // =========================================================================

  Future<List<RecommendationItem>> recommendCalories({
    int? targetCalories,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    final response = await generateRecommendation(
      RecommendationGenerateRequest(
        mealType: 'any',
        targetCalories: targetCalories ?? 2000,
        maxResults: top,
        excludeUserAllergies: excludeUserAllergies,
      ),
    );
    return response?.items ?? [];
  }

  Future<List<RecommendationItem>> recommendLunch({
    int? targetCalories,
    int? budgetVnd,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    final response = await generateRecommendation(
      RecommendationGenerateRequest(
        mealType: 'lunch',
        targetCalories: targetCalories ?? 700,
        maxResults: top,
        excludeUserAllergies: excludeUserAllergies,
      ),
    );
    return response?.items ?? [];
  }

  Future<List<RecommendationItem>> recommendEco({
    int? budgetVnd,
    int? limitMinutes,
    int top = 10,
    bool excludeUserAllergies = true,
  }) async {
    final response = await generateBudgetAware(
      BudgetAwareRequest(
        mealType: 'any',
        maxBudgetVnd: budgetVnd ?? 50000,
        maxResults: top,
        excludeUserAllergies: excludeUserAllergies,
      ),
    );
    return response?.items ?? [];
  }

  Future<DailyMenuPlan?> recommendDailyMenu({
    int? targetCalories,
    bool excludeUserAllergies = true,
  }) async {
    final response = await _api.postJson(
      ApiEndpoints.recommendationGenerateDailyMenu,
      {
        'MealType': 'any',
        'TargetCalories': targetCalories ?? 2000,
        'MaxResults': 3,
        'ExcludeUserAllergies': excludeUserAllergies,
      },
    );
    final recommendation = RecommendationGenerateResponse.fromJson(
      _requireObject(response, 'Không thể tạo thực đơn trong ngày'),
    );
    final items = recommendation.items
        .map(
          (item) => DailyMenuPlanItem(
            id: item.id,
            name: item.name,
            mealType: item.mealType ?? 'snack',
            foodId: item.isFood ? item.id : null,
            recipeId: item.isFood ? null : item.id,
            sourceEntityType: item.type,
            targetCalories: item.caloriesKcal.round(),
            recommendation: item,
          ),
        )
        .toList();

    return DailyMenuPlan(
      targetCalories: recommendation.targetCalories ?? targetCalories ?? 2000,
      totalCalories: recommendation.totalCalories,
      items: items,
    );
  }

  // =========================================================================
  // GENERATE METHODS (Extended)
  // =========================================================================

  Future<RecommendationGenerateResponse?> generateRecommendation(
    RecommendationGenerateRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.recommendationGenerate,
      request.toJson(),
    );
    return RecommendationGenerateResponse.fromJson(
      _requireObject(response, 'Không thể tải gợi ý'),
    );
  }

  Future<RecommendationGenerateResponse?> generateSafeRecommendation(
    SafeRecommendationRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.recommendationGenerateSafe,
      request.toJson(),
    );
    return RecommendationGenerateResponse.fromJson(
      _requireObject(response, 'Không thể tải gợi ý an toàn'),
    );
  }

  Future<WeeklyPlanResponse?> generateWeeklyPlan(
    WeeklyPlanRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.recommendationGenerateWeeklyPlan,
      request.toJson(),
    );
    return WeeklyPlanResponse.fromJson(
      _requireObject(response, 'Không thể tạo thực đơn tuần'),
    );
  }

  Future<BudgetAwareResponse?> generateBudgetAware(
    BudgetAwareRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.recommendationGenerateBudgetAware,
      request.toJson(),
    );
    return BudgetAwareResponse.fromJson(
      _requireObject(response, 'Không thể tải gợi ý theo ngân sách'),
    );
  }

  // =========================================================================
  // HISTORY & DETAIL METHODS
  // =========================================================================

  Future<List<RecommendationHistoryItem>> getHistory({int page = 1, int pageSize = 10}) async {
    final queryParams = 'page=$page&pageSize=$pageSize';
    final response = await _api.get('${ApiEndpoints.recommendationHistory}?$queryParams');
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw StateError(_responseError(response, 'Không thể tải lịch sử gợi ý'));
    }
    final decoded = jsonDecode(response.body);
    
    // Handle both array response (for backward compatibility) and paginated response
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .map(RecommendationHistoryItem.fromJson)
          .toList();
    }
    
    // Paginated response format
    if (decoded is Map) {
      final items = decoded['items'] ?? decoded['data'] ?? decoded['history'] ?? [];
      return (items as List)
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .map(RecommendationHistoryItem.fromJson)
          .toList();
    }
    
    throw const FormatException('Lịch sử gợi ý trả về dữ liệu không đúng định dạng.');
  }

  Future<RecommendationDetail?> getById(String id) async {
    final response = await _api.get(ApiEndpoints.recommendationById(id));
    return RecommendationDetail.fromJson(
      _requireObject(response, 'Không thể tải chi tiết gợi ý'),
    );
  }

  // =========================================================================
  // PREVIEW METHOD
  // =========================================================================

  Future<RecommendationGenerateResponse?> preview(
    RecommendationPreviewRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.recommendationPreview,
      request.toJson(),
    );
    return RecommendationGenerateResponse.fromJson(
      _requireObject(response, 'Không thể xem trước gợi ý'),
    );
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
        {
          'Rating': feedback.isLiked ? 5 : 1,
          if (feedback.comment != null) 'Comment': feedback.comment,
          'WouldRecommend': feedback.isLiked,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<FeedbackSummary?> getFeedbackSummary() async {
    final response = await _api.get(ApiEndpoints.recommendationFeedbackSummary);
    return FeedbackSummary.fromJson(
      _requireObject(response, 'Không thể tải thống kê phản hồi'),
    );
  }

  // =========================================================================
  // EXPLAIN METHOD
  // =========================================================================

  Future<String?> explain(String id) async {
    final response = await _api.get(ApiEndpoints.recommendationExplain(id));
    final decoded = _requireObject(response, 'Không thể tải lý do gợi ý');
    final explanation = decoded['explanation'] ?? decoded['Explanation'] ?? decoded['message'] ?? decoded['Message'];
    if (explanation != null) return explanation.toString();
    final reasons = decoded['reasons'] ?? decoded['Reasons'];
    if (reasons is List) return reasons.map((reason) => reason.toString()).join('\n');
    return null;
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
        if (calories != null) 'targetCalories': '$calories',
        if (excludeAllergies != null) 'excludeUserAllergies': excludeAllergies.toString(),
      };
      final response = await _api.get(
        ApiEndpoints.recommendationScores + _query(params),
      );
      return RecommendationScore.fromJson(
        _requireObject(response, 'Không thể tải điểm phù hợp'),
      );
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


}
