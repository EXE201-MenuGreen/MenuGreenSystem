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
  Future<Map<String, dynamic>> createPtReport(
    String weekStart,
    int expiry,
  ) async => _map(
    _body(
      await _api.postJson('${ApiEndpoints.baseUrl}/PtReview/reports', {
        'weekStartDate': weekStart,
        'expirationDays': expiry,
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
  Future<void> connect(String id) async => _body(
    await _api.postJson('${ApiEndpoints.baseUrl}/Coaches/connect/$id', {}),
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
  Future<Map<String, dynamic>> clientNutrition(String id) async => _map(
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

  Future<List<Map<String, dynamic>>> ingredients(
    String keyword,
    bool safe,
  ) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/Ingredient/search').replace(
      queryParameters: {'keyword': keyword, if (safe) 'allergyMode': 'safe'},
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
  Future<void> userAction(String id, String action, [String? role]) async =>
      _body(
        await _api.putJson(
          '${ApiEndpoints.baseUrl}/User/$id/$action',
          role == null ? {} : {'role': role},
        ),
      );

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  List<Map<String, dynamic>> _list(dynamic value) =>
      (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}
