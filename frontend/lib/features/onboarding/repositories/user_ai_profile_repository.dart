import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class UserAiProfileRepository {
  UserAiProfileRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<({bool success, String message})> upsert({
    String? eatingPattern,
    String? preferencesJson,
    bool? allergiesAcknowledged,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (eatingPattern != null) body['eatingPattern'] = eatingPattern;
      if (preferencesJson != null) body['preferences'] = preferencesJson;
      if (allergiesAcknowledged != null) {
        body['allergiesAcknowledged'] = allergiesAcknowledged;
      }

      final response = await _api.putJson(ApiEndpoints.userAiProfileMe, body);
      if (response.statusCode == 200) {
        return (success: true, message: 'Đã lưu sở thích');
      }
      return (success: false, message: _errorMessage(response.body));
    } catch (_) {
      return (success: false, message: 'Không thể kết nối đến máy chủ');
    }
  }

  static String buildPreferencesJson(List<String> selectedLabels) {
    return jsonEncode({
      'eatingPreferences': selectedLabels,
    });
  }

  String _errorMessage(String body) {
    if (body.isEmpty) return 'Lưu hồ sơ AI thất bại';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['Message'];
        if (message != null) return message.toString();
      }
    } catch (_) {}
    return 'Lưu hồ sơ AI thất bại';
  }
}
