// Repositories for the `Vietnam Local Features` group (2.11 – 2.18).
//
// Each repository wraps the corresponding `ApiEndpoints` constants and decodes
// responses into the models defined in `vietnam_local_models.dart`. Errors are
// surfaced via `_apiCall` so callers can display translated messages.
import 'dart:convert';

import '../../../core/i18n/api_message_translator.dart';
import '../../../core/middleware/error_middleware.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/vietnam_local_models.dart';

/// Result wrapper used to surface translated backend messages with decoded
/// payloads. Fields that fail to decode gracefully yield `success = false`.
class ApiResult<T> {
  const ApiResult({required this.success, this.data, this.message});

  final bool success;
  final T? data;
  final String? message;

  String get translatedMessage => ApiMessageTranslator.translate(message);
}

/// Lightweight execution helper that converts non-2xx responses into
/// Vietnamese-translated messages so screens can show them directly.
class _VietnamLocalApi {
  _VietnamLocalApi();

  Future<ApiResult<dynamic>> _exec(Future<dynamic> Function() run) async {
    try {
      final response = await run();
      if (response is ApiException) {
        return ApiResult<dynamic>(success: false, message: response.message);
      }
      final status = response.statusCode ?? 200;
      if (status >= 200 && status < 300) {
        if (response.body == null || response.body!.isEmpty) {
          return const ApiResult<dynamic>(success: true);
        }
        final decoded = jsonDecode(response.body!);
        return ApiResult<dynamic>(success: true, data: decoded);
      }
      final msg = _extractMessage(response.body) ?? 'Máy chủ phản hồi lỗi.';
      return ApiResult<dynamic>(success: false, message: msg);
    } catch (e) {
      return ApiResult<dynamic>(
        success: false,
        message: 'Lỗi kết nối máy chủ.',
      );
    }
  }

  String? _extractMessage(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const [
          'message',
          'Message',
          'error',
          'Error',
          'title',
        ]) {
          final v = decoded[key];
          if (v is String && v.isNotEmpty) return v;
        }
      }
    } catch (_) {}
    return null;
  }
}

class DailyStarterRepository {
  DailyStarterRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(),
      _http = _VietnamLocalApi();

  final ApiClient _api;
  final _VietnamLocalApi _http;

  Future<ApiResult<DailyStarterToday>> getToday() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.dailyStarterToday),
    );
    if (!result.success) {
      return ApiResult<DailyStarterToday>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = DailyStarterToday.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<DailyStarterToday>(success: true, data: data);
    } catch (e) {
      return ApiResult<DailyStarterToday>(
        success: false,
        message: 'Không đọc được dữ liệu.',
      );
    }
  }

  Future<ApiResult<List<DailyStarterFood>>> getFeaturedMeals() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.dailyStarterFeaturedMeals),
    );
    if (!result.success) {
      return ApiResult<List<DailyStarterFood>>(
        success: false,
        message: result.message,
      );
    }
    final raw = result.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : (raw is Map<String, dynamic> && raw['data'] is List
                    ? raw['data'] as List
                    : <dynamic>[]));
    final data = list
        .whereType<Map>()
        .map((e) => DailyStarterFood.fromJson(e.cast<String, dynamic>()))
        .toList();
    return ApiResult<List<DailyStarterFood>>(success: true, data: data);
  }

  Future<ApiResult<String>> selectMeal(Map<String, dynamic> payload) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.dailyStarterSelectMeal, payload),
    );
    return ApiResult<String>(
      success: result.success,
      message: result.message,
      data: result.success
          ? ApiMessageTranslator.translate(
              (result.data is Map<String, dynamic> &&
                      (result.data['message'] ?? result.data['Message']) !=
                          null)
                  ? (result.data['message'] ?? result.data['Message'])
                        .toString()
                  : (result.message ?? ''),
            )
          : null,
    );
  }

  Future<ApiResult<DailyStarterStartLog>> startLog() async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.dailyStarterStartLog, const {}),
    );
    if (!result.success) {
      return ApiResult<DailyStarterStartLog>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = DailyStarterStartLog.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<DailyStarterStartLog>(success: true, data: data);
    } catch (_) {
      return ApiResult<DailyStarterStartLog>(
        success: false,
        message: 'Không đọc được dữ liệu gợi ý.',
      );
    }
  }

  Future<ApiResult<DailyStarterPersonalization>> getPersonalization() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.dailyStarterPersonalization),
    );
    if (!result.success) {
      return ApiResult<DailyStarterPersonalization>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = DailyStarterPersonalization.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<DailyStarterPersonalization>(success: true, data: data);
    } catch (_) {
      return ApiResult<DailyStarterPersonalization>(
        success: false,
        message: 'Không đọc được thông tin cá nhân hóa.',
      );
    }
  }

  Future<ApiResult<DailyStarterPersonalization>> updatePersonalization(
    Map<String, dynamic> payload,
  ) async {
    final result = await _http._exec(
      () => _api.putJson(ApiEndpoints.dailyStarterPersonalization, payload),
    );
    if (!result.success) {
      return ApiResult<DailyStarterPersonalization>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = DailyStarterPersonalization.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<DailyStarterPersonalization>(success: true, data: data);
    } catch (_) {
      return ApiResult<DailyStarterPersonalization>(
        success: false,
        message: 'Không đọc được phản hồi máy chủ.',
      );
    }
  }

  Future<ApiResult<List<LocalRecommendationItem>>> getRecommendations({
    int? targetCalories,
    int? budgetVnd,
    int? top,
  }) async {
    final params = <String, String>{};
    if (targetCalories != null) params['targetCalories'] = '$targetCalories';
    if (budgetVnd != null) params['budgetVnd'] = '$budgetVnd';
    if (top != null) params['top'] = '$top';
    final url = Uri.parse(
      ApiEndpoints.dailyStarterRecommendations,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<List<LocalRecommendationItem>>(
        success: false,
        message: result.message,
      );
    }
    final raw = result.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : <dynamic>[]);
    final data = list
        .whereType<Map>()
        .map((e) => LocalRecommendationItem.fromJson(e.cast<String, dynamic>()))
        .toList();
    return ApiResult<List<LocalRecommendationItem>>(success: true, data: data);
  }
}

class GymGoalsRepository {
  GymGoalsRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(),
      _http = _VietnamLocalApi();

  final ApiClient _api;
  final _VietnamLocalApi _http;

  Future<ApiResult<GymGoalProfile>> getMe() async {
    final result = await _http._exec(() => _api.get(ApiEndpoints.gymGoalsMe));
    if (!result.success) {
      return ApiResult<GymGoalProfile>(success: false, message: result.message);
    }
    try {
      final raw = (result.data as Map).cast<String, dynamic>();
      final profile = LocalPreferencesProfile.fromJson(raw);
      final prefs = _decodePreferences(profile.preferences);
      return ApiResult<GymGoalProfile>(
        success: true,
        data: GymGoalProfile.fromJson(prefs),
      );
    } catch (_) {
      return ApiResult<GymGoalProfile>(
        success: false,
        message: 'Không đọc được cấu hình gym.',
      );
    }
  }

  Future<ApiResult<GymGoalProfile>> upsert(GymGoalProfile profile) async {
    final preferences = jsonEncode(profile.toJson());
    final payload = <String, dynamic>{
      'goalMode': profile.goalMode,
      'weeklyTrainingSchedule': profile.weeklyTrainingSchedule,
      'trainingDaysPerWeek': profile.trainingDaysPerWeek,
      'restDaysPerWeek': profile.restDaysPerWeek,
      'trainingDayTargetCalories': profile.trainingDayTargetCalories,
      'restDayTargetCalories': profile.restDayTargetCalories,
      'minCalories': profile.minCalories,
      'maxCalories': profile.maxCalories,
      'minProteinG': profile.minProteinG,
      'maxProteinG': profile.maxProteinG,
      'targetWeightKg': profile.targetWeightKg,
      'targetBodyFatPercent': profile.targetBodyFatPercent,
      'notes': profile.notes,
      'Preferences': preferences,
    };
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.gymGoalsSetup, payload),
    );
    return ApiResult<GymGoalProfile>(
      success: result.success,
      message: result.message,
    );
  }

  Future<ApiResult<List<LocalRecommendationItem>>> getPlan({
    int? targetCalories,
    int? top,
  }) async {
    final params = <String, String>{};
    if (targetCalories != null && targetCalories > 0) {
      params['targetCalories'] = '$targetCalories';
    }
    if (top != null) params['top'] = '$top';
    final url = Uri.parse(
      ApiEndpoints.gymGoalsPlan,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<List<LocalRecommendationItem>>(
        success: false,
        message: result.message,
      );
    }
    final raw = result.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : <dynamic>[]);
    final data = list
        .whereType<Map>()
        .map((e) => LocalRecommendationItem.fromJson(e.cast<String, dynamic>()))
        .toList();
    return ApiResult<List<LocalRecommendationItem>>(success: true, data: data);
  }

  Future<ApiResult<GymRecalibrationResult>> recalibrate({
    String? period = 'week',
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final payload = <String, dynamic>{
      'period': ?period,
      'date': ?(date == null ? null : _formatDateOnly(date)),
      'startDate': ?(startDate == null ? null : _formatDateOnly(startDate)),
      'endDate': ?(endDate == null ? null : _formatDateOnly(endDate)),
      'range': 'week',
    };
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.gymGoalsRecalibrate, payload),
    );
    if (!result.success) {
      return ApiResult<GymRecalibrationResult>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = GymRecalibrationResult.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<GymRecalibrationResult>(success: true, data: data);
    } catch (_) {
      return ApiResult<GymRecalibrationResult>(
        success: false,
        message: 'Không đọc được kết quả hiệu chỉnh.',
      );
    }
  }

  Future<ApiResult<dynamic>> getAlerts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = _formatDateOnly(startDate);
    if (endDate != null) params['endDate'] = _formatDateOnly(endDate);
    final url = Uri.parse(
      ApiEndpoints.gymGoalsAlerts,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  String _formatDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class SafetyRepository {
  SafetyRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(),
      _http = _VietnamLocalApi();

  final ApiClient _api;
  final _VietnamLocalApi _http;

  Future<ApiResult<SafetyDisclaimer>> getDisclaimer() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.safetyDisclaimer),
    );
    if (!result.success) {
      return ApiResult<SafetyDisclaimer>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = SafetyDisclaimer.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<SafetyDisclaimer>(success: true, data: data);
    } catch (_) {
      return ApiResult<SafetyDisclaimer>(
        success: false,
        message: 'Không đọc được nội dung miễn trừ trách nhiệm.',
      );
    }
  }

  Future<ApiResult<SafetyConsent>> getConsent() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.safetyConsent),
    );
    if (!result.success) {
      return ApiResult<SafetyConsent>(success: false, message: result.message);
    }
    try {
      final data = SafetyConsent.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<SafetyConsent>(success: true, data: data);
    } catch (_) {
      return ApiResult<SafetyConsent>(
        success: false,
        message: 'Không đọc được cài đặt đồng ý.',
      );
    }
  }

  Future<ApiResult<SafetyConsent>> updateConsent(SafetyConsent consent) async {
    final result = await _http._exec(
      () => _api.putJson(ApiEndpoints.safetyConsent, consent.toJson()),
    );
    if (!result.success) {
      return ApiResult<SafetyConsent>(success: false, message: result.message);
    }
    return ApiResult<SafetyConsent>(success: true, data: consent);
  }

  Future<ApiResult<SafetyAlerts>> getAlerts() async {
    final result = await _http._exec(() => _api.get(ApiEndpoints.safetyAlerts));
    if (!result.success) {
      return ApiResult<SafetyAlerts>(success: false, message: result.message);
    }
    try {
      final data = SafetyAlerts.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<SafetyAlerts>(success: true, data: data);
    } catch (_) {
      return ApiResult<SafetyAlerts>(
        success: false,
        message: 'Không đọc được cảnh báo y khoa.',
      );
    }
  }

  Future<ApiResult<dynamic>> exportData() async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.safetyExportData, const {}),
    );
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  Future<ApiResult<String>> deleteData() async {
    final result = await _http._exec(
      () => _api.delete(ApiEndpoints.safetyDeleteData),
    );
    return ApiResult<String>(
      success: result.success,
      message: result.message,
      data: result.message,
    );
  }

  Future<ApiResult<String>> reportIssue({
    required String category,
    required String severity,
    required String description,
    String? contactEmail,
  }) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.safetyReportIssue, {
        'category': category,
        'severity': severity,
        'description': description,
        if (contactEmail != null && contactEmail.isNotEmpty)
          'contactEmail': contactEmail,
      }),
    );
    return ApiResult<String>(
      success: result.success,
      message: result.message,
      data: result.message,
    );
  }
}

class FoodCaptureRepository {
  FoodCaptureRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(),
      _http = _VietnamLocalApi();

  final ApiClient _api;
  final _VietnamLocalApi _http;

  Future<ApiResult<dynamic>> quickTemplate(Map<String, dynamic> payload) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.foodCaptureQuickTemplate, payload),
    );
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  Future<ApiResult<dynamic>> templateFromPlan(DateTime date) async {
    final params = <String, String>{'date': _formatDateOnly(date)};
    final url = Uri.parse(
      ApiEndpoints.foodCaptureTemplateFromPlan,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  Future<ApiResult<dynamic>> fallbackEstimate(
    Map<String, dynamic> payload,
  ) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.foodCaptureFallbackEstimate, payload),
    );
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  Future<ApiResult<dynamic>> saveAsQuickAdd(
    Map<String, dynamic> payload,
  ) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.foodCaptureSaveAsQuickAdd, payload),
    );
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  String _formatDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class LocalPreferencesRepository {
  LocalPreferencesRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(),
      _http = _VietnamLocalApi();

  final ApiClient _api;
  final _VietnamLocalApi _http;

  Future<ApiResult<LocalPreferencesProfile>> get() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.localPreferences),
    );
    if (!result.success) {
      return ApiResult<LocalPreferencesProfile>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = LocalPreferencesProfile.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<LocalPreferencesProfile>(success: true, data: data);
    } catch (_) {
      return ApiResult<LocalPreferencesProfile>(
        success: false,
        message: 'Không đọc được sở thích ăn uống.',
      );
    }
  }

  Future<ApiResult<LocalPreferencesProfile>> upsert(
    Map<String, dynamic> payload,
  ) async {
    final result = await _http._exec(
      () => _api.putJson(ApiEndpoints.localPreferences, payload),
    );
    if (!result.success) {
      return ApiResult<LocalPreferencesProfile>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = LocalPreferencesProfile.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<LocalPreferencesProfile>(success: true, data: data);
    } catch (_) {
      return ApiResult<LocalPreferencesProfile>(
        success: true,
        message: 'Đã lưu sở thích ăn uống.',
      );
    }
  }

  Future<ApiResult<List<LocalRecommendationItem>>> getBudgetAware({
    int? budgetVnd,
    int? targetCalories,
    int? top,
  }) async {
    final params = <String, String>{};
    if (budgetVnd != null) params['BudgetVnd'] = '$budgetVnd';
    if (targetCalories != null) params['TargetCalories'] = '$targetCalories';
    if (top != null) params['top'] = '$top';
    final url = Uri.parse(
      ApiEndpoints.localRecommendationsBudgetAware,
    ).replace(queryParameters: params);
    return _listResult(url);
  }

  Future<ApiResult<List<LocalRecommendationItem>>> getLocalFriendly({
    int? targetCalories,
    int? top,
  }) async {
    final params = <String, String>{};
    if (targetCalories != null) params['TargetCalories'] = '$targetCalories';
    if (top != null) params['top'] = '$top';
    final url = Uri.parse(
      ApiEndpoints.localRecommendationsLocalFriendly,
    ).replace(queryParameters: params);
    return _listResult(url);
  }

  Future<ApiResult<dynamic>> sendFeedback(Map<String, dynamic> payload) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.localRecommendationsFeedback, payload),
    );
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  /// POST /api/Nutrition/meal-log/vn — ghi meal log với đơn vị VN (chén, bát...).
  Future<ApiResult<dynamic>> createVnMealLog(
    Map<String, dynamic> payload,
  ) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.mealLogVn, payload),
    );
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  /// GET /api/Nutrition/meal-log/vn/history — lịch sử meal log VN.
  Future<ApiResult<List<Map<String, dynamic>>>> getVnMealLogHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _http._exec(
      () => _api.get(
        '${ApiEndpoints.mealLogVnHistory}?page=$page&pageSize=$pageSize',
      ),
    );
    if (!result.success) {
      return ApiResult<List<Map<String, dynamic>>>(
        success: false,
        message: result.message,
      );
    }
    try {
      final raw = result.data;
      final items = raw is Map && raw['items'] is List
          ? raw['items'] as List
          : (raw is List ? raw : <dynamic>[]);
      final data = items
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      return ApiResult<List<Map<String, dynamic>>>(success: true, data: data);
    } catch (_) {
      return ApiResult<List<Map<String, dynamic>>>(
        success: false,
        message: 'Không đọc được lịch sử.',
      );
    }
  }

  /// GET /api/Nutrition/discovery/local — tìm món ăn local theo keyword.
  Future<ApiResult<List<Map<String, dynamic>>>> discoveryLocal({
    String? keyword,
    int? maxPriceVnd,
  }) async {
    final params = <String, String>{};
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (maxPriceVnd != null) params['maxPriceVnd'] = '$maxPriceVnd';
    final url = Uri.parse(
      ApiEndpoints.nutritionDiscoveryLocal,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<List<Map<String, dynamic>>>(
        success: false,
        message: result.message,
      );
    }
    try {
      final raw = result.data;
      final items = raw is List
          ? raw
          : (raw is Map && raw['items'] is List
                ? raw['items'] as List
                : <dynamic>[]);
      final data = items
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      return ApiResult<List<Map<String, dynamic>>>(success: true, data: data);
    } catch (_) {
      return ApiResult<List<Map<String, dynamic>>>(
        success: false,
        message: 'Không tìm được món ăn.',
      );
    }
  }

  /// GET /api/Nutrition/discovery/local/by-budget — tìm món theo ngân sách.
  Future<ApiResult<List<Map<String, dynamic>>>> discoveryLocalByBudget({
    required int maxPriceVnd,
  }) async {
    final url = Uri.parse(
      '${ApiEndpoints.nutritionDiscoveryLocalByBudget}?maxPrice=$maxPriceVnd',
    );
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<List<Map<String, dynamic>>>(
        success: false,
        message: result.message,
      );
    }
    try {
      final raw = result.data;
      final items = raw is List
          ? raw
          : (raw is Map && raw['items'] is List
                ? raw['items'] as List
                : <dynamic>[]);
      final data = items
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      return ApiResult<List<Map<String, dynamic>>>(success: true, data: data);
    } catch (_) {
      return ApiResult<List<Map<String, dynamic>>>(
        success: false,
        message: 'Không tìm được món theo ngân sách.',
      );
    }
  }

  Future<ApiResult<List<LocalRecommendationItem>>> _listResult(Uri url) async {
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<List<LocalRecommendationItem>>(
        success: false,
        message: result.message,
      );
    }
    final raw = result.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : <dynamic>[]);
    final data = list
        .whereType<Map>()
        .map((e) => LocalRecommendationItem.fromJson(e.cast<String, dynamic>()))
        .toList();
    return ApiResult<List<LocalRecommendationItem>>(success: true, data: data);
  }
}

class PlannedVsActualRepository {
  PlannedVsActualRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(),
      _http = _VietnamLocalApi();

  final ApiClient _api;
  final _VietnamLocalApi _http;

  Future<ApiResult<PlannedVsActualSummary>> getSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = _formatDateOnly(from);
    if (to != null) params['to'] = _formatDateOnly(to);
    final url = Uri.parse(
      ApiEndpoints.plannedVsActualSummary,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<PlannedVsActualSummary>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = PlannedVsActualSummary.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<PlannedVsActualSummary>(success: true, data: data);
    } catch (_) {
      return ApiResult<PlannedVsActualSummary>(
        success: false,
        message: 'Không đọc được báo cáo kế hoạch/thực tế.',
      );
    }
  }

  Future<ApiResult<AdherenceScore>> getAdherenceScore({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = _formatDateOnly(from);
    if (to != null) params['to'] = _formatDateOnly(to);
    final url = Uri.parse(
      ApiEndpoints.plannedVsActualAdherenceScore,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<AdherenceScore>(success: false, message: result.message);
    }
    try {
      final data = AdherenceScore.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<AdherenceScore>(success: true, data: data);
    } catch (_) {
      return ApiResult<AdherenceScore>(
        success: false,
        message: 'Không đọc được điểm bám sát.',
      );
    }
  }

  Future<ApiResult<DriftAnalysis>> getDriftAnalysis({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = _formatDateOnly(from);
    if (to != null) params['to'] = _formatDateOnly(to);
    final url = Uri.parse(
      ApiEndpoints.plannedVsActualDriftAnalysis,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    if (!result.success) {
      return ApiResult<DriftAnalysis>(success: false, message: result.message);
    }
    try {
      final data = DriftAnalysis.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<DriftAnalysis>(success: true, data: data);
    } catch (_) {
      return ApiResult<DriftAnalysis>(
        success: false,
        message: 'Không đọc được phân tích lệch kế hoạch.',
      );
    }
  }

  Future<ApiResult<PlannedVsActualRecommendations>> getRecommendations() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.plannedVsActualRecommendations),
    );
    if (!result.success) {
      return ApiResult<PlannedVsActualRecommendations>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = PlannedVsActualRecommendations.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<PlannedVsActualRecommendations>(
        success: true,
        data: data,
      );
    } catch (_) {
      return ApiResult<PlannedVsActualRecommendations>(
        success: false,
        message: 'Không đọc được gợi ý.',
      );
    }
  }

  Future<ApiResult<dynamic>> recalibrate() async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.plannedVsActualRecalibrate, const {}),
    );
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  /// GET /api/Analytics/planned-vs-actual/monthly-report — báo cáo tháng (JSON hoặc HTML).
  Future<ApiResult<dynamic>> getMonthlyReport({
    int? month,
    int? year,
    String format = 'json',
  }) async {
    final params = <String, String>{};
    if (month != null) params['month'] = '$month';
    if (year != null) params['year'] = '$year';
    if (format.isNotEmpty) params['format'] = format;
    final url = Uri.parse(
      ApiEndpoints.plannedVsActualMonthlyReport,
    ).replace(queryParameters: params);
    final result = await _http._exec(() => _api.get(url.toString()));
    return ApiResult<dynamic>(
      success: result.success,
      message: result.message,
      data: result.data,
    );
  }

  String _formatDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class IngredientSubstitutionPreferencesRepository {
  IngredientSubstitutionPreferencesRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(),
      _http = _VietnamLocalApi();

  final ApiClient _api;
  final _VietnamLocalApi _http;

  Future<ApiResult<List<IngredientSubstitutePreference>>> list() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.ingredientSubstitutesPreferences),
    );
    if (!result.success) {
      return ApiResult<List<IngredientSubstitutePreference>>(
        success: false,
        message: result.message,
      );
    }
    final raw = result.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : <dynamic>[]);
    final data = list
        .whereType<Map>()
        .map(
          (e) => IngredientSubstitutePreference.fromJson(
            e.cast<String, dynamic>(),
          ),
        )
        .toList();
    return ApiResult<List<IngredientSubstitutePreference>>(
      success: true,
      data: data,
    );
  }

  Future<ApiResult<IngredientSubstitutePreference>> create(
    Map<String, dynamic> payload,
  ) async {
    final result = await _http._exec(
      () =>
          _api.postJson(ApiEndpoints.ingredientSubstitutesPreferences, payload),
    );
    if (!result.success) {
      return ApiResult<IngredientSubstitutePreference>(
        success: false,
        message: result.message,
      );
    }
    try {
      final data = IngredientSubstitutePreference.fromJson(
        (result.data as Map).cast<String, dynamic>(),
      );
      return ApiResult<IngredientSubstitutePreference>(
        success: true,
        data: data,
      );
    } catch (_) {
      return ApiResult<IngredientSubstitutePreference>(
        success: true,
        message: result.message,
      );
    }
  }

  Future<ApiResult<String>> delete(String id) async {
    final result = await _http._exec(
      () => _api.delete(ApiEndpoints.ingredientSubstitutePreferenceById(id)),
    );
    return ApiResult<String>(
      success: result.success,
      message: result.message,
      data: result.message,
    );
  }
}

class LuckyWheelRepository {
  LuckyWheelRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  final _VietnamLocalApi _http = _VietnamLocalApi();

  Future<ApiResult<List<LuckyWheelFood>>> getFoods() async {
    final result = await _http._exec(
      () => _api.get(ApiEndpoints.luckyWheelFoods),
    );
    if (!result.success) {
      return ApiResult<List<LuckyWheelFood>>(
        success: false,
        message: result.message,
      );
    }
    final raw = result.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : (raw is Map<String, dynamic> && raw['data'] is List
                    ? raw['data'] as List
                    : <dynamic>[]));
    final data = list
        .whereType<Map>()
        .map((e) => LuckyWheelFood.fromJson(e.cast<String, dynamic>()))
        .toList();
    return ApiResult<List<LuckyWheelFood>>(success: true, data: data);
  }

  Future<ApiResult<String>> applySelection(
    String foodId,
    String mealType,
  ) async {
    final result = await _http._exec(
      () => _api.postJson(ApiEndpoints.luckyWheelApply, {
        'foodId': foodId,
        'mealType': mealType,
      }),
    );
    return ApiResult<String>(
      success: result.success,
      message: result.message,
      data: result.message,
    );
  }
}

Map<String, dynamic> _decodePreferences(String? raw) {
  if (raw == null || raw.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return <String, dynamic>{};
}
