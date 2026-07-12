import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/meal_template_models.dart';

class MealTemplateRepository {
  MealTemplateRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<MealTemplate>> getAll() async {
    final response = await _api.get(ApiEndpoints.mealTemplates);
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception(_message(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((item) => MealTemplate.fromJson(item.cast<String, dynamic>())).toList();
  }

  Future<MealTemplate> getById(String id) => _templateResponse(_api.get(ApiEndpoints.mealTemplateById(id)));

  Future<MealTemplate> create(Map<String, dynamic> body) =>
      _templateResponse(_api.postJson(ApiEndpoints.mealTemplates, body));

  Future<MealTemplate> update(String id, Map<String, dynamic> body) =>
      _templateResponse(_api.putJson(ApiEndpoints.mealTemplateById(id), body));

  Future<void> delete(String id) async {
    final response = await _api.delete(ApiEndpoints.mealTemplateById(id));
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  Future<MealTemplate> duplicate(String id) =>
      _templateResponse(_api.postJson(ApiEndpoints.mealTemplateDuplicate(id), const {}));

  Future<void> log(
    String id, {
    required String mealType,
    required DateTime loggedAt,
    List<Map<String, dynamic>> itemQuantities = const [],
  }) async {
    final response = await _api.postJson(ApiEndpoints.mealTemplateLog(id), {
      'mealType': mealType,
      'loggedAt': loggedAt.toUtc().toIso8601String(),
      'itemQuantities': itemQuantities,
    });
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  Future<MealTemplate> createFromLog(String mealLogId, String title) {
    final uri = Uri.parse(ApiEndpoints.mealTemplateFromLog(mealLogId))
        .replace(queryParameters: {'title': title});
    return _templateResponse(_api.postJson(uri.toString(), const {}));
  }

  Future<MealTemplate> _templateResponse(Future<dynamic> request) async {
    final response = await request;
    if ((response.statusCode != 200 && response.statusCode != 201) || response.body.isEmpty) {
      throw Exception(_message(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('Phản hồi không hợp lệ.');
    return MealTemplate.fromJson(decoded);
  }

  String _message(dynamic response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return (decoded['message'] ?? decoded['Message'] ?? 'Không thể thực hiện thao tác.').toString();
    } catch (_) {}
    return 'Không thể thực hiện thao tác.';
  }
}
