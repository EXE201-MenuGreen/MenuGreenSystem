import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class AdvancedRepository {
  AdvancedRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  dynamic _body(http.Response response) {
    final dynamic data = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? (data['message'] ?? data['Message']) : null;
      throw Exception(
        message?.toString() ?? 'Yêu cầu thất bại (${response.statusCode})',
      );
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> ptRequests() async => _list(
    _body(await _api.get('${ApiEndpoints.baseUrl}/PtReview/my-requests')),
  );

  // Phase 8: PersonalProgram (Coach -> Gymer)
  Future<List<Map<String, dynamic>>> myPersonalPrograms() async => _list(
    _body(
      await _api.get('${ApiEndpoints.baseUrl}/PtReview/my-personal-programs'),
    ),
  );

  Future<Map<String, dynamic>> acceptPersonalProgram(String id) async => _map(
    _body(
      await _api.postJson(
        '${ApiEndpoints.baseUrl}/PtReview/personal-programs/$id/accept',
        {},
      ),
    ),
  );

  Future<Map<String, dynamic>> rejectPersonalProgram(String id) async => _map(
    _body(
      await _api.postJson(
        '${ApiEndpoints.baseUrl}/PtReview/personal-programs/$id/reject',
        {},
      ),
    ),
  );

  Future<Map<String, dynamic>> createPtReport(
    String weekStart,
    int expiry, {
    String requestType = 'WeeklyReport',
    String? studentNote,
    double? checkInWeight,
    double? checkInBodyFat,
    int? trainingDaysCount,
    String? bodyFeeling,
  }) async => _map(
    _body(
      await _api.postJson('${ApiEndpoints.baseUrl}/PtReview/reports', {
        'weekStartDate': weekStart,
        'expirationDays': expiry,
        'requestType': requestType,
        'studentNote': studentNote,
        'checkInWeight': checkInWeight,
        'checkInBodyFat': checkInBodyFat,
        'trainingDaysCount': trainingDaysCount,
        'bodyFeeling': bodyFeeling,
      }),
    ),
  );
  Future<Map<String, dynamic>> ptResult(String id) async => _map(
    _body(
      await _api.get('${ApiEndpoints.baseUrl}/PtReview/requests/$id/result'),
    ),
  );
  Future<void> ptAction(String id, String action) async => _body(
    await _api.postJson(
      '${ApiEndpoints.baseUrl}/PtReview/requests/$id/$action',
      {},
    ),
  );
  Future<Map<String, dynamic>> sharedPtReport(String token) async => _map(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/PtReview/shared-reports/$token',
        authenticated: false,
      ),
    ),
  );
  Future<void> submitPtReview(String token, Map<String, dynamic> body) async =>
      _body(
        await _api.postJson(
          '${ApiEndpoints.baseUrl}/PtReview/shared-reports/$token/submit',
          body,
          authenticated: false,
        ),
      );

  Future<Map<String, dynamic>?> budget() async {
    final response = await _api.get('${ApiEndpoints.baseUrl}/BudgetRequest/me');
    if (response.statusCode == 404 ||
        response.body.isEmpty ||
        response.body == 'null') {
      return null;
    }
    return _map(_body(response));
  }

  Future<Map<String, dynamic>> saveBudget({
    String? id,
    required int amount,
    required int minutes,
  }) async {
    final body = {'budgetVnd': amount, 'timeLimitMin': minutes};
    return _map(
      _body(
        id == null
            ? await _api.postJson('${ApiEndpoints.baseUrl}/BudgetRequest', body)
            : await _api.putJson(
                '${ApiEndpoints.baseUrl}/BudgetRequest/$id',
                body,
              ),
      ),
    );
  }

  Future<void> deleteBudget(String id) async =>
      _body(await _api.delete('${ApiEndpoints.baseUrl}/BudgetRequest/$id'));

  Future<List<Map<String, dynamic>>> coaches({String? keyword}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/Coaches').replace(
      queryParameters: {
        if (keyword != null && keyword.isNotEmpty) 'specialty': keyword,
      },
    );
    return _list(_body(await _api.get(uri.toString(), authenticated: false)));
  }

  Future<List<Map<String, dynamic>>> clients() async => _list(
    _body(await _api.get('${ApiEndpoints.baseUrl}/Coaches/my-clients')),
  );
  Future<List<Map<String, dynamic>>> myCoaches() async => _list(
    _body(await _api.get('${ApiEndpoints.baseUrl}/Coaches/my-coaches')),
  );
  Future<List<Map<String, dynamic>>> myCoachFeedback() async => _list(
    _body(await _api.get('${ApiEndpoints.baseUrl}/Coaches/my-feedback')),
  );
  Future<void> connect(String id) async => _body(
    await _api.postJson('${ApiEndpoints.baseUrl}/Coaches/connect/$id', {}),
  );
  Future<void> disconnect(String id) async => _body(
    await _api.postJson('${ApiEndpoints.baseUrl}/Coaches/disconnect/$id', {}),
  );
  Future<void> access(String id, bool grant) async => _body(
    await _api.postJson(
      '${ApiEndpoints.baseUrl}/Coaches/${grant ? 'grant' : 'revoke'}-access/$id',
      {},
    ),
  );
  Future<void> registerCoach(Map<String, dynamic> body) async => _body(
    await _api.postJson('${ApiEndpoints.baseUrl}/Coaches/register', body),
  );
  Future<Map<String, dynamic>> coach(String id) async => _map(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/Coaches/$id',
        authenticated: false,
      ),
    ),
  );
  Future<void> approveClient(String id, bool approve) async => _body(
    await _api.postJson(
      '${ApiEndpoints.baseUrl}/Coaches/approve-connection/$id',
      {'approve': approve},
    ),
  );
  Future<Map<String, dynamic>> clientProfile(String id) async => _map(
    _body(
      await _api.get('${ApiEndpoints.baseUrl}/Coaches/clients/$id/profile'),
    ),
  );
  Future<List<Map<String, dynamic>>> clientNutrition(String id) async => _list(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/Coaches/clients/$id/nutrition-summary?days=7',
      ),
    ),
  );
  Future<List<Map<String, dynamic>>> clientWeight(String id) async => _list(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/Coaches/clients/$id/weight-trend',
      ),
    ),
  );
  Future<List<Map<String, dynamic>>> feedback(String id) async => _list(
    _body(
      await _api.get('${ApiEndpoints.baseUrl}/Coaches/clients/$id/feedback'),
    ),
  );
  Future<void> addFeedback(String id, String type, String content) async =>
      _body(
        await _api.postJson(
          '${ApiEndpoints.baseUrl}/Coaches/clients/$id/feedback',
          {'feedbackType': type, 'content': content},
        ),
      );
  Future<void> adjustTargets(String id, Map<String, dynamic> body) async =>
      _body(
        await _api.putJson(
          '${ApiEndpoints.baseUrl}/Coaches/clients/$id/health-targets',
          body,
        ),
      );
  Future<void> adjustMealPlan(
    String clientId,
    String planId,
    Map<String, dynamic> body,
  ) async => _body(
    await _api.putJson(
      '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plan/$planId',
      body,
    ),
  );

  Future<Map<String, dynamic>?> clientMealPlan(
    String clientId,
    String dateString,
  ) async {
    final response = await _api.get(
      '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plan?date=$dateString',
    );
    if (response.statusCode == 404 ||
        response.body.isEmpty ||
        response.body == 'null') {
      return null;
    }
    return _map(_body(response));
  }

  Future<List<Map<String, dynamic>>> clientSuggestions(
    String clientId, {
    DateTime? date,
    int? targetCalories,
    int? minCalories,
    int? maxCalories,
    double? minProteinG,
    double? maxProteinG,
    int? top,
  }) async {
    final params = <String, String>{};
    if (date != null) params['date'] = _dateOnly(date);
    if (targetCalories != null) params['targetCalories'] = '$targetCalories';
    if (minCalories != null) params['minCalories'] = '$minCalories';
    if (maxCalories != null) params['maxCalories'] = '$maxCalories';
    if (minProteinG != null) params['minProteinG'] = '$minProteinG';
    if (maxProteinG != null) params['maxProteinG'] = '$maxProteinG';
    if (top != null) params['top'] = '$top';
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/suggestions',
    ).replace(queryParameters: params);
    return _list(_body(await _api.get(uri.toString())));
  }

  Future<Map<String, dynamic>> clientGymConfig(
    String clientId,
    DateTime date,
  ) async {
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/gym-config',
    ).replace(queryParameters: {'date': _dateOnly(date)});
    return _map(_body(await _api.get(uri.toString())));
  }

  Future<List<Map<String, dynamic>>> clientReviewRequests(
    String clientId,
  ) async => _list(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/review-requests',
      ),
    ),
  );

  Future<List<Map<String, dynamic>>> ingredients(
    String keyword,
    bool safe, {
    String? category,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/Ingredient/search').replace(
      queryParameters: {
        'keyword': keyword,
        if (safe) 'allergyMode': 'safe',
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    return _list(_body(await _api.get(uri.toString())));
  }

  Future<Map<String, dynamic>> ingredient(String id, bool safe) async => _map(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/Ingredient/$id${safe ? '?allergyMode=safe' : ''}',
      ),
    ),
  );
  Future<List<Map<String, dynamic>>> ingredientRecipes(String id) async =>
      _list(
        _body(await _api.get('${ApiEndpoints.baseUrl}/Ingredient/$id/recipes')),
      );
  Future<void> saveIngredient(String? id, Map<String, dynamic> body) async =>
      _body(
        id == null
            ? await _api.postJson('${ApiEndpoints.baseUrl}/Ingredient', body)
            : await _api.putJson(
                '${ApiEndpoints.baseUrl}/Ingredient/$id',
                body,
              ),
      );
  Future<void> deleteIngredient(String id) async =>
      _body(await _api.delete('${ApiEndpoints.baseUrl}/Ingredient/$id'));

  Future<List<Map<String, dynamic>>> users() async =>
      _list(_body(await _api.get('${ApiEndpoints.baseUrl}/User')));
  Future<Map<String, dynamic>> user(String id) async =>
      _map(_body(await _api.get('${ApiEndpoints.baseUrl}/User/$id')));
  Future<void> userAction(String id, String action, [String? role]) async =>
      _body(
        await _api.putJson(
          '${ApiEndpoints.baseUrl}/User/$id/$action',
          role == null ? {} : {'role': role},
        ),
      );

  // =========================================================================
  // COACH MEAL-PLAN OPERATIONS (Phase 1 backend - /api/Coaches/clients/...)
  // Coach views, creates, edits, submits and deletes meal plans on behalf
  // of a connected Gymer.
  // =========================================================================

  Future<List<Map<String, dynamic>>> clientMealPlans(
    String clientId, {
    DateTime? from,
    DateTime? to,
    String? planType,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = _dateOnly(from);
    if (to != null) params['to'] = _dateOnly(to);
    if (planType != null && planType.isNotEmpty) params['planType'] = planType;
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plans',
    ).replace(queryParameters: params);
    return _list(_body(await _api.get(uri.toString())));
  }

  Future<Map<String, dynamic>> clientMealPlanDetail(
    String clientId,
    String planId,
  ) async => _map(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plans/$planId',
      ),
    ),
  );

  Future<Map<String, dynamic>> createClientMealPlan(
    String clientId,
    Map<String, dynamic> body,
  ) async => _map(
    _body(
      await _api.postJson(
        '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plans',
        body,
      ),
    ),
  );

  Future<Map<String, dynamic>> updateClientMealPlan(
    String clientId,
    String planId,
    Map<String, dynamic> body,
  ) async => _map(
    _body(
      await _api.putJson(
        '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plan/$planId',
        body,
      ),
    ),
  );

  Future<Map<String, dynamic>> submitClientMealPlan(
    String clientId,
    String planId, {
    String? notes,
    int? minCalories,
    int? maxCalories,
  }) async => _map(
    _body(
      await _api.postJson(
        '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plans/$planId/submit',
        {
          ?notes == null ? null : 'notes': notes,
          ?minCalories == null ? null : 'minCalories': minCalories,
          ?maxCalories == null ? null : 'maxCalories': maxCalories,
        },
      ),
    ),
  );

  Future<void> deleteClientMealPlan(
    String clientId,
    String planId,
  ) async => _body(
    await _api.delete(
      '${ApiEndpoints.baseUrl}/Coaches/clients/$clientId/meal-plans/$planId',
    ),
  );

  // =========================================================================
  // COACH WEEKLY-REPORT OPERATIONS (Phase 2 backend - /api/PtReview/coach/...)
  // =========================================================================

  Future<List<Map<String, dynamic>>> coachWeeklyReports({
    DateTime? weekStart,
    String? month,
    String? status,
    String? clientId,
  }) async {
    final params = <String, String>{};
    if (weekStart != null) params['weekStart'] = _dateOnly(weekStart);
    if (month != null && month.isNotEmpty) params['month'] = month;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (clientId != null && clientId.isNotEmpty) params['clientId'] = clientId;
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl}/PtReview/coach/reports',
    ).replace(queryParameters: params);
    return _list(_body(await _api.get(uri.toString())));
  }

  Future<Map<String, dynamic>> coachReportDetail(String reportId) async => _map(
    _body(
      await _api.get(
        '${ApiEndpoints.baseUrl}/PtReview/coach/reports/$reportId',
      ),
    ),
  );

  Future<void> submitCoachReview(
    String reportId,
    Map<String, dynamic> body,
  ) async => _body(
    await _api.postJson(
      '${ApiEndpoints.baseUrl}/PtReview/coach/reports/$reportId/review',
      body,
    ),
  );

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  List<Map<String, dynamic>> _list(dynamic value) =>
      (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}
