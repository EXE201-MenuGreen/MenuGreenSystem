import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import '../../../core/middleware/query_middleware.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/nutrition_models.dart';

export '../models/nutrition_models.dart';

class NutritionTrackingRepository {
  NutritionTrackingRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

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
    final response = await _api.delete(ApiEndpoints.nutritionMealLogById(mealLogId));
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
    final response = await _api.delete(ApiEndpoints.nutritionWeightLogById(weightLogId));
    return response.statusCode == 200;
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
  }) {
    return {
      'foodId': foodId,
      'recipeId': recipeId,
      'mealType': mealType,
      'quantityG': quantityG,
      'notes': notes,
      'loggedAt': loggedAt?.toUtc().toIso8601String(),
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
      'recordedAt': recordedAt?.toUtc().toIso8601String(),
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
    );
    if (response.statusCode != 200 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return CvInferenceResponse.fromJson(decoded);
  }
}
