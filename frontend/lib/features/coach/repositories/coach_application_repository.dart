import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class CoachApplicationRepository {
  CoachApplicationRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> getMine() async {
    final response = await _api.get(ApiEndpoints.coachApplication);
    if (response.statusCode != 200) {
      throw Exception('Không thể tải hồ sơ PT.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveDraft(Map<String, dynamic> data) async {
    final response = await _api.putJson(ApiEndpoints.coachApplication, data);
    if (response.statusCode != 200) {
      throw Exception(_message(response.body, 'Không thể lưu bản nháp.'));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submit(Map<String, dynamic> data) async {
    final response = await _api.postJson(
      ApiEndpoints.coachApplicationSubmit,
      data,
    );
    if (response.statusCode != 200) {
      throw Exception(
        _message(response.body, 'Không thể gửi hồ sơ xét duyệt.'),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _message(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] ?? decoded['Message'])?.toString() ??
            fallback;
      }
    } catch (_) {}
    return fallback;
  }
}
