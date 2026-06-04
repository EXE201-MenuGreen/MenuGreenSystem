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
