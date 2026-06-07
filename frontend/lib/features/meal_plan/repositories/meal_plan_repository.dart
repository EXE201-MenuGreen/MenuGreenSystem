import 'dart:convert';

import '../../../core/i18n/api_message_translator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/meal_plan_models.dart';

class MealPlanRepository {
  MealPlanRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  String _dateQuery(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<UserMealPlan?> getByDate(DateTime date) async {
    try {
      final response = await _api.get('${ApiEndpoints.userMealPlans}?date=${_dateQuery(date)}');
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return UserMealPlan.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<MealPlanAdherence?> getAdherence(DateTime date) async {
    try {
      final response =
          await _api.get('${ApiEndpoints.userMealPlanAdherence}?date=${_dateQuery(date)}');
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return MealPlanAdherence.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<UserMealPlan?> createFromDailyMenu({
    required DateTime plannedDate,
    required int? targetCalories,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      'plannedDate': _dateQuery(plannedDate),
      if (targetCalories != null) 'targetCalories': targetCalories,
      'items': items,
    };
    return _postPlan(ApiEndpoints.userMealPlansFromDailyMenu, body);
  }

  Future<UserMealPlan?> completeItem(String itemId) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.userMealPlanCompleteItem(itemId),
        {},
      );
      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception(_messageFromResponse(response));
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final item = decoded['item'] ?? decoded['Item'];
      if (item is Map<String, dynamic>) {
        final plan = await getByDate(DateTime.now());
        return plan;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserMealPlan?> _postPlan(String url, Map<String, dynamic> body) async {
    try {
      final response = await _api.postJson(url, body);
      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception(_messageFromResponse(response));
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return UserMealPlan.fromJson(decoded);
    } catch (e) {
      rethrow;
    }
  }

  String _messageFromResponse(dynamic response) {
    try {
      final decoded = jsonDecode(response.body as String);
      if (decoded is Map && decoded['message'] != null) {
        return ApiMessageTranslator.translate(decoded['message'].toString());
      }
      if (decoded is Map && decoded['Message'] != null) {
        return ApiMessageTranslator.translate(decoded['Message'].toString());
      }
    } catch (_) {}
    return 'Không thực hiện được thao tác kế hoạch bữa ăn.';
  }
}
