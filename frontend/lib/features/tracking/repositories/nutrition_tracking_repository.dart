import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import '../../../core/middleware/query_middleware.dart';
import '../../../core/middleware/error_middleware.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/nutrition_models.dart';
import '../models/latest_weight_log.dart';

export '../models/nutrition_models.dart';

class NutritionTrackingRepository {
  NutritionTrackingRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<MealDaySummary?> getDailySummary(DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await _api.get(
      QueryMiddleware.buildUrl(ApiEndpoints.nutritionDaily, {'date': dateStr}),
    );
    if (response.statusCode != 200 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return MealDaySummary.fromJson(decoded);
  }

  Future<NutritionDashboard?> getDashboard({
    String range = 'week',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, String>{'range': range};
    if (startDate != null) params['startDate'] = _formatDate(startDate);
    if (endDate != null) params['endDate'] = _formatDate(endDate);
    final response = await _api.get(
      QueryMiddleware.buildUrl(ApiEndpoints.nutritionDashboard, params),
    );
    if (response.statusCode != 200 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return NutritionDashboard.fromJson(decoded);
  }

  Future<bool> createMealLog({
    String? foodId,
    String? recipeId,
    required String mealType,
    required double quantityG,
    String? notes,
    DateTime? loggedAt,
    double? caloriesKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? customName,
  }) async {
    final response = await _api.postJson(
      ApiEndpoints.nutritionMealLogs,
      _mealLogBody(
        foodId: foodId,
        recipeId: recipeId,
        mealType: mealType,
        quantityG: quantityG,
        notes: notes,
        loggedAt: loggedAt,
        caloriesKcal: caloriesKcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        customName: customName,
      ),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateMealLog(
    String mealLogId, {
    String? foodId,
    String? recipeId,
    required String mealType,
    required double quantityG,
    String? notes,
    DateTime? loggedAt,
  }) async {
    final response = await _api.putJson(
      ApiEndpoints.nutritionMealLogById(mealLogId),
      _mealLogBody(
        foodId: foodId,
        recipeId: recipeId,
        mealType: mealType,
        quantityG: quantityG,
        notes: notes,
        loggedAt: loggedAt,
      ),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteMealLog(String mealLogId) async {
    final response = await _api.delete(
      ApiEndpoints.nutritionMealLogById(mealLogId),
    );
    return response.statusCode == 200;
  }

  Future<bool> createWeightLog({
    required double weightKg,
    double? bodyFatPercent,
    DateTime? recordedAt,
  }) async {
    final response = await _api.postJson(
      ApiEndpoints.nutritionWeightLogs,
      _weightLogBody(
        weightKg: weightKg,
        bodyFatPercent: bodyFatPercent,
        recordedAt: recordedAt,
      ),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateWeightLog(
    String weightLogId, {
    required double weightKg,
    double? bodyFatPercent,
    DateTime? recordedAt,
  }) async {
    final response = await _api.putJson(
      ApiEndpoints.nutritionWeightLogById(weightLogId),
      _weightLogBody(
        weightKg: weightKg,
        bodyFatPercent: bodyFatPercent,
        recordedAt: recordedAt,
      ),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteWeightLog(String weightLogId) async {
    final response = await _api.delete(
      ApiEndpoints.nutritionWeightLogById(weightLogId),
    );
    return response.statusCode == 200;
  }

  /// Fetch the user's most-recent weight log. Used to pre-fill the
  /// weight log sheet so the user doesn't have to re-type a value they
  /// already entered. Returns null when the API call fails or the user
  /// has no logs yet.
  Future<LatestWeightLog?> getLatestWeightLog() async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.nutritionWeightLogs}?page=1&pageSize=1',
      );
      if (response.statusCode != 200) return _getHealthProfileWeight();
      final body = response.body;
      if (body.isEmpty) return _getHealthProfileWeight();
      final decoded = jsonDecode(body);
      Map<String, dynamic>? first;
      if (decoded is Map) {
        final rawLogs =
            decoded['weightLogs'] ??
            decoded['WeightLogs'] ??
            decoded['items'] ??
            decoded['Items'] ??
            decoded['data'] ??
            decoded['Data'];
        if (rawLogs is List && rawLogs.isNotEmpty && rawLogs.first is Map) {
          first = Map<String, dynamic>.from(rawLogs.first as Map);
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        first = Map<String, dynamic>.from(decoded.first as Map);
      }
      if (first == null) return _getHealthProfileWeight();
      return LatestWeightLog.fromJson(first);
    } catch (_) {
      return _getHealthProfileWeight();
    }
  }

  Future<LatestWeightLog?> _getHealthProfileWeight() async {
    try {
      final response = await _api.get(ApiEndpoints.healthProfileMe);
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded);
      final weight = data['weightKg'] ?? data['WeightKg'];
      if (weight == null) return null;
      return LatestWeightLog.fromJson({
        'id': '',
        'weightKg': weight,
        'bodyFatPercent': data['bodyFatPercent'] ?? data['BodyFatPercent'],
      });
    } catch (_) {
      return null;
    }
  }

  Future<List<CatalogItem>> getFoods({String? keyword}) async {
    final response = await _api.get(
      QueryMiddleware.buildUrl(ApiEndpoints.foods, {'keyword': keyword}),
    );
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final items = decoded['items'];
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => CatalogItem.fromJson(e, fallbackNameKey: 'nameVi'))
        .toList();
  }

  Future<List<CatalogItem>> getIngredients({String? keyword}) async {
    final response = await _api.get(
      QueryMiddleware.buildUrl(ApiEndpoints.ingredientSearch, {
        'keyword': keyword,
        'isActive': 'true',
      }),
    );
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final items = decoded['items'] ?? decoded['Items'];
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => CatalogItem.fromJson(e, fallbackNameKey: 'nameVi'))
        .toList();
  }

  Future<List<CatalogItem>> getRecipes({String? keyword}) async {
    final response = await _api.get(
      QueryMiddleware.buildUrl(ApiEndpoints.recipeSearch, {'keyword': keyword}),
    );
    if (response.statusCode != 200 || response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final items = decoded['items'];
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => CatalogItem.fromJson(e, fallbackNameKey: 'title'))
        .toList();
  }

  Map<String, dynamic> _mealLogBody({
    String? foodId,
    String? recipeId,
    required String mealType,
    required double quantityG,
    String? notes,
    DateTime? loggedAt,
    double? caloriesKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? customName,
  }) {
    return {
      'foodId': foodId,
      'recipeId': recipeId,
      'mealType': mealType,
      'quantityG': quantityG,
      'notes': notes,
      // Always include the UTC marker. A timestamp without an offset can be
      // interpreted in the API server's timezone and fall on yesterday.
      'loggedAt': loggedAt?.toUtc().toIso8601String(),
      'caloriesKcal': caloriesKcal,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'customName': customName,
      'addToMealPlan': true,
    };
  }

  Map<String, dynamic> _weightLogBody({
    required double weightKg,
    double? bodyFatPercent,
    DateTime? recordedAt,
  }) {
    return {
      'weightKg': weightKg,
      'bodyFatPercent': bodyFatPercent,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<CvInferenceResponse?> analyzeFoodImage(
    List<int> fileBytes,
    String filename, {
    required String mimeType,
  }) async {
    final response = await _api.postMultipart(
      ApiEndpoints.cvAnalyze,
      fileBytes,
      'image',
      filename,
      fileContentType: MediaType.parse(mimeType),
      // Backend submits a CV job and polls the AI worker for up to 60 seconds.
      // This request must not inherit the 20-second timeout used by normal APIs.
      timeout: const Duration(seconds: 90),
    );
    if (response.statusCode != 200) {
      throw StateError(ApiErrorMiddleware.messageForResponse(response));
    }
    if (response.body.isEmpty) {
      throw const FormatException('Máy chủ không trả về kết quả phân tích.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Kết quả phân tích không đúng định dạng.');
    }
    return CvInferenceResponse.fromJson(decoded);
  }

  Future<Map<String, dynamic>> analyzePreparedMealImage(
    List<int> fileBytes,
    String filename, {
    required String mimeType,
  }) async {
    final response = await _api.postMultipart(
      ApiEndpoints.cvAnalyzePreparedMeal,
      fileBytes,
      'image',
      filename,
      fileContentType: MediaType.parse(mimeType),
      timeout: const Duration(seconds: 115),
    );
    if (response.statusCode != 200) {
      throw StateError(ApiErrorMiddleware.messageForResponse(response));
    }
    if (response.body.isEmpty) {
      throw const FormatException('Không nhận được kết quả phân tích món ăn.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Kết quả phân tích món ăn không đúng định dạng.',
      );
    }
    return decoded;
  }
}
