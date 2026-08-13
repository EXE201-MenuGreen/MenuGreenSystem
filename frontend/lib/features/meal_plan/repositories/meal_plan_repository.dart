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

  // Cache for getPlans
  List<MealPlanListItem>? _plansCache;
  DateTime? _plansCacheTime;
  static const _plansCacheDuration = Duration(minutes: 5);

  // Cache for getByDate
  UserMealPlan? _todayCache;
  DateTime? _todayCacheTime;
  static const _todayCacheDuration = Duration(minutes: 2);

  // Cache for getDashboard
  MealPlanDayDashboard? _dashboardCache;
  DateTime? _dashboardCacheTime;
  static const _dashboardCacheDuration = Duration(minutes: 2);

  // Cache for getStreaks
  MealPlanStreak? _streaksCache;
  DateTime? _streaksCacheTime;
  static const _streaksCacheDuration = Duration(minutes: 5);

  String _dateQuery(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _invalidateCache() {
    _plansCache = null;
    _plansCacheTime = null;
    _todayCache = null;
    _todayCacheTime = null;
    _dashboardCache = null;
    _dashboardCacheTime = null;
  }

  // ==================== User Meal Plan (Daily) ====================

  Future<UserMealPlan?> getByDate(DateTime date) async {
    return _getByDate(date, forceRefresh: false);
  }

  /// Reloads the effective plan from the database-facing API. Use this before
  /// mutations that require a current item ID, because daily plans can be
  /// regenerated while an approval snapshot is still open on screen.
  Future<UserMealPlan?> getByDateFresh(DateTime date) async {
    return _getByDate(date, forceRefresh: true);
  }

  Future<UserMealPlan?> _getByDate(
    DateTime date, {
    required bool forceRefresh,
  }) async {
    // Check cache for today's data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final queryDate = DateTime(date.year, date.month, date.day);

    if (!forceRefresh &&
        queryDate == today &&
        _todayCache != null &&
        _todayCacheTime != null) {
      if (now.difference(_todayCacheTime!) < _todayCacheDuration) {
        return _todayCache;
      }
    }

    try {
      final response = await _api.get(
        '${ApiEndpoints.userMealPlans}?date=${_dateQuery(date)}'
        '${forceRefresh ? '&refresh=true' : ''}',
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final result = UserMealPlan.fromJson(decoded);

      // Cache today's data
      if (queryDate == today) {
        _todayCache = result;
        _todayCacheTime = now;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  Future<MealPlanAdherence?> getAdherence(DateTime date) async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.userMealPlanAdherence}?date=${_dateQuery(date)}',
      );
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
      // Invalidate cache on mutation
      _invalidateCache();
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return await getByDate(DateTime.now());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleItem(String itemId, bool isCompleted) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.userMealPlanToggleItem(itemId, isCompleted),
        {},
      );
      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception(_messageFromResponse(response));
      }
      // Invalidate cache on mutation
      _invalidateCache();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Full Meal Plan CRUD ====================

  /// Lấy danh sách tất cả meal plans
  Future<List<MealPlanListItem>> getPlans({bool? isActive}) async {
    // Check cache
    if (_plansCache != null && _plansCacheTime != null) {
      if (DateTime.now().difference(_plansCacheTime!) < _plansCacheDuration) {
        return _plansCache!;
      }
    }

    try {
      var url = ApiEndpoints.mealPlans;
      if (isActive != null) {
        url += '?isActive=$isActive';
      }
      final response = await _api.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        final result = decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => MealPlanListItem.fromJson(json))
            .toList();

        // Update cache
        _plansCache = result;
        _plansCacheTime = DateTime.now();

        return result;
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
  Future<MealPlanDetail> createPlanWithItems(
    CreatePlanWithItemsRequest request,
  ) async {
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
  Future<MealPlanDetail> updatePlan(
    String id,
    CreatePlanRequest request,
  ) async {
    final response = await _api.putJson(
      ApiEndpoints.mealPlanById(id),
      request.toJson(),
    );
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
  Future<MealPlanDetail> duplicatePlan(
    String id,
    DuplicatePlanRequest request,
  ) async {
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
  Future<MealPlanItemDetail> addItem(
    String planId,
    AddItemRequest request,
  ) async {
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

  Future<UserMealPlan> balanceDailyCalories({
    required String planId,
    required DateTime plannedDate,
    required int targetCalories,
    required List<String> itemIds,
    bool preservePlanTarget = false,
  }) async {
    final response = await _api
        .postJson(ApiEndpoints.mealPlanBalanceCalories(planId), {
          'plannedDate': _dateQuery(plannedDate),
          'targetCalories': targetCalories,
          'itemIds': itemIds,
          'preservePlanTarget': preservePlanTarget,
        });
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    _invalidateCache();
    return UserMealPlan.fromJson(decoded);
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
    _invalidateCache();
    return ConvertToLogResult.fromJson(decoded);
  }

  // ==================== Dashboard & Stats ====================

  /// Dashboard theo ngày
  Future<MealPlanDayDashboard> getDashboard(DateTime date) async {
    // Check cache for today's dashboard
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final queryDate = DateTime(date.year, date.month, date.day);

    if (queryDate == today &&
        _dashboardCache != null &&
        _dashboardCacheTime != null) {
      if (now.difference(_dashboardCacheTime!) < _dashboardCacheDuration) {
        return _dashboardCache!;
      }
    }

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
    final result = MealPlanDayDashboard.fromJson(decoded);

    // Cache today's dashboard
    if (queryDate == today) {
      _dashboardCache = result;
      _dashboardCacheTime = now;
    }

    return result;
  }

  /// Streaks
  Future<MealPlanStreak> getStreaks() async {
    // Check cache
    if (_streaksCache != null && _streaksCacheTime != null) {
      if (DateTime.now().difference(_streaksCacheTime!) <
          _streaksCacheDuration) {
        return _streaksCache!;
      }
    }

    final response = await _api.get(ApiEndpoints.mealPlanStreaks);
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    final result = MealPlanStreak.fromJson(decoded);

    // Update cache
    _streaksCache = result;
    _streaksCacheTime = DateTime.now();

    return result;
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

  /// Creates a weekly budget-aware plan. For Office users the API selects
  /// recipes within the configured cooking-time limit and labels it lunchbox-ready.
  Future<MealPlanDetail> generateBudgetLunchboxPlan() async {
    final response = await _api.postJson(
      ApiEndpoints.mealPlanGenerateByBudget,
      const {},
    );
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    // The endpoint makes the previous generated plan inactive and returns a
    // new one. Keep the list cache in sync so a later refresh cannot restore
    // the old plan on the Office roadmap.
    _invalidateCache();
    return MealPlanDetail.fromJson(decoded);
  }

  Future<Map<String, dynamic>> getGroceryList(String planId) async {
    final response = await _api.get(ApiEndpoints.mealPlanGroceryList(planId));
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return decoded;
  }

  /// Save an AI scan as a planned Office meal, without recording it as eaten.
  Future<void> saveOfficeScanPlanItem(
    String planId,
    OfficeScanMealRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.mealPlanScanPlanItems(planId),
      request.toJson(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    _invalidateCache();
  }

  /// Save today's AI scan as the priority lunch. It remains planned until
  /// the user explicitly marks it as eaten.
  Future<void> saveOfficePriorityLunch(
    String planId,
    OfficeScanMealRequest request,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.mealPlanPriorityLunch(planId),
      request.toJson(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    _invalidateCache();
  }

  /// Get budget status for a plan
  Future<Map<String, dynamic>> getBudgetStatus(String planId) async {
    final response = await _api.get(ApiEndpoints.mealPlanBudgetStatus(planId));
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return decoded;
  }

  /// Get alternatives for an item
  Future<List<MealPlanItemDetail>> getAlternatives(
    String planId,
    String itemId,
  ) async {
    final response = await _api.get(
      ApiEndpoints.mealPlanAlternatives(planId, itemId),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => MealPlanItemDetail.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Replace item with alternative
  Future<MealPlanDetail> replaceItem(
    String planId,
    String itemId,
    String newFoodId,
  ) async {
    final response = await _api.postJson(
      ApiEndpoints.mealPlanReplaceItem(planId, itemId),
      {'newFoodId': newFoodId},
    );
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return MealPlanDetail.fromJson(decoded);
  }

  // ==================== Helpers ====================

  String _messageFromResponse(dynamic response) {
    try {
      if (response != null && response.body != null) {
        final bodyStr = response.body.toString().trim();
        if (bodyStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(bodyStr);
            if (decoded is Map<String, dynamic>) {
              if (decoded.containsKey('errors') && decoded['errors'] is Map) {
                final errorsMap = decoded['errors'] as Map;
                if (errorsMap.isNotEmpty) {
                  final firstVal = errorsMap.values.first;
                  if (firstVal is List && firstVal.isNotEmpty) {
                    return ApiMessageTranslator.translate(
                      firstVal.first.toString(),
                    );
                  }
                  return ApiMessageTranslator.translate(firstVal.toString());
                }
              }
              final rawMsg =
                  decoded['message'] ??
                  decoded['Message'] ??
                  decoded['title'] ??
                  decoded['Title'] ??
                  decoded['detail'] ??
                  decoded['Detail'] ??
                  decoded['error'] ??
                  decoded['Error'];
              if (rawMsg != null && rawMsg.toString().isNotEmpty) {
                return ApiMessageTranslator.translate(rawMsg.toString());
              }
            }
          } catch (_) {}
          final translated = ApiMessageTranslator.translate(bodyStr);
          if (translated.isNotEmpty) return translated;
        }
      }
    } catch (_) {}
    return 'Không thực hiện được thao tác kế hoạch bữa ăn.';
  }
}
