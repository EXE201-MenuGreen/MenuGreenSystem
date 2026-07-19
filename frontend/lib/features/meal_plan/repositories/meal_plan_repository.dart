import 'dart:convert';

import '../../../core/i18n/api_message_translator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/meal_plan_models.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';

class MealPlanRepository {
  MealPlanRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  String _dateQuery(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ==================== User Meal Plan (Daily) ====================

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
    final body = <String, dynamic>{
      'plannedDate': _dateQuery(plannedDate),
      'items': items,
    };
    if (targetCalories != null) {
      body['targetCalories'] = targetCalories;
    }
    final String endpoint = ApiEndpoints.userMealPlans;
    try {
      final response = await _api.postJson('$endpoint/from-daily-menu', body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_messageFromResponse(response));
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return UserMealPlan.fromJson(decoded);
    } catch (e) {
      rethrow;
    }
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
      return await getByDate(DateTime.now());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserMealPlan?> toggleItem(String itemId, bool isCompleted) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.userMealPlanToggleItem(itemId, isCompleted),
        {},
      );
      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception(_messageFromResponse(response));
      }
      return await getByDate(DateTime.now());
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Full Meal Plan CRUD ====================

  /// Lấy danh sách tất cả meal plans
  Future<List<MealPlanListItem>> getPlans({bool? isActive}) async {
    try {
      var url = ApiEndpoints.mealPlans;
      if (isActive != null) {
        url += '?isActive=$isActive';
      }
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => MealPlanListItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy chi tiết một meal plan
  Future<MealPlanDetail?> getPlanDetail(String id) async {
    try {
      final response = await _api.get(ApiEndpoints.mealPlanById(id));
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return MealPlanDetail.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Tạo meal plan mới
  Future<MealPlanDetail> createPlan(CreatePlanRequest request) async {
    final url = ApiEndpoints.mealPlans;
    final response = await _api.postJson(url, request.toJson());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanDetail.fromJson(decoded);
  }

  /// Tạo meal plan rỗng (không cần items) - user tạo plan trước, thêm items sau.
  Future<MealPlanDetail> createEmptyPlan(CreateEmptyPlanRequest request) async {
    final url = ApiEndpoints.mealPlansCreateEmpty;
    final response = await _api.postJson(url, request.toJson());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanDetail.fromJson(decoded);
  }

  /// Tạo meal plan với items ngay từ đầu
  Future<MealPlanDetail> createPlanWithItems(CreatePlanWithItemsRequest request) async {
    final url = ApiEndpoints.mealPlansCreateWithItems;
    final response = await _api.postJson(url, request.toJson());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanDetail.fromJson(decoded);
  }

  /// Cập nhật meal plan
  Future<MealPlanDetail> updatePlan(String id, CreatePlanRequest request) async {
    final response = await _api.putJson(ApiEndpoints.mealPlanById(id), request.toJson());
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanDetail.fromJson(decoded);
  }

  /// Xóa meal plan
  Future<void> deletePlan(String id) async {
    final response = await _api.delete(ApiEndpoints.mealPlanById(id));
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
  }

  /// Cập nhật trạng thái meal plan
  Future<void> updatePlanStatus(String id, String status) async {
    final response = await _api.patchJson(
      '${ApiEndpoints.mealPlanById(id)}/status',
      {'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
  }

  /// Nhân bản meal plan
  Future<MealPlanDetail> duplicatePlan(String id, DuplicatePlanRequest request) async {
    final response = await _api.postJson(
      ApiEndpoints.mealPlanDuplicate(id),
      request.toJson(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanDetail.fromJson(decoded);
  }

  // ==================== Meal Plan Items ====================

  /// Thêm item vào meal plan
  Future<MealPlanItemDetail> addItem(String planId, AddItemRequest request) async {
    final response = await _api.postJson(
      ApiEndpoints.mealPlanItems(planId),
      request.toJson(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanItemDetail.fromJson(decoded);
  }

  /// Cập nhật item
  Future<MealPlanItemDetail> updateItem(
    String planId,
    String itemId,
    AddItemRequest request,
  ) async {
    final response = await _api.putJson(
      ApiEndpoints.mealPlanItem(planId, itemId),
      request.toJson(),
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanItemDetail.fromJson(decoded);
  }

  /// Xóa item
  Future<void> deleteItem(String planId, String itemId) async {
    final response = await _api.delete(
      ApiEndpoints.mealPlanItem(planId, itemId),
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
  }

  /// Cập nhật trạng thái item
  Future<MealPlanItemDetail> updateItemStatus(
    String planId,
    String itemId,
    String status,
  ) async {
    final response = await _api.patchJson(
      ApiEndpoints.mealPlanItemStatus(planId, itemId),
      {'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanItemDetail.fromJson(decoded);
  }

  /// Chuyển item thành meal log
  Future<ConvertToLogResult> convertItemToLog(
    String planId,
    String itemId,
    ConvertToLogRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.mealPlanItemConvertToLog(planId, itemId),
      request.toJson(),
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return ConvertToLogResult.fromJson(decoded);
  }

  // ==================== Dashboard & Stats ====================

  /// Dashboard theo ngày
  Future<MealPlanDayDashboard> getDashboard(DateTime date) async {
    final response = await _api.get(
      '${ApiEndpoints.mealPlanDashboard}?date=${_dateQuery(date)}',
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanDayDashboard.fromJson(decoded);
  }

  /// So sánh planned vs actual
  Future<MealPlanCompare> getCompare(DateTime from, DateTime to) async {
    final response = await _api.get(
      '${ApiEndpoints.mealPlanCompare}?from=${_dateQuery(from)}&to=${_dateQuery(to)}',
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanCompare.fromJson(decoded);
  }

  /// Streaks
  Future<MealPlanStreak> getStreaks() async {
    final response = await _api.get(ApiEndpoints.mealPlanStreaks);
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanStreak.fromJson(decoded);
  }

  /// Creates a weekly budget-aware plan. For Office users the API selects
  /// recipes within the configured cooking-time limit and labels it lunchbox-ready.
  Future<MealPlanDetail> generateBudgetLunchboxPlan() async {
    final response = await _api.postJson(ApiEndpoints.mealPlanGenerateByBudget, const {});
    if (response.statusCode != 200 || response.body.isEmpty) throw Exception(_messageFromResponse(response));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('Invalid response format');
    return MealPlanDetail.fromJson(decoded);
  }

  Future<Map<String, dynamic>> getGroceryList(String planId) async {
    final response = await _api.get(ApiEndpoints.mealPlanGroceryList(planId));
    if (response.statusCode != 200 || response.body.isEmpty) throw Exception(_messageFromResponse(response));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('Invalid response format');
    return decoded;
  }

  // ==================== Helpers ====================

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
