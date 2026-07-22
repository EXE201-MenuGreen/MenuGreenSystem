import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class UserAiProfileRepository {
  UserAiProfileRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<bool> isOfficeMode() async {
    try {
      final response = await _api.get(ApiEndpoints.userAiProfileMe);
      if (response.statusCode != 200 || response.body.isEmpty) return false;
      final data = jsonDecode(response.body);
      if (data is! Map) return false;
      final raw = (data['eatingPattern'] ?? data['EatingPattern'] ?? '').toString();
      return raw.replaceAll('"', '').trim().toLowerCase() == 'office';
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String message, bool requiresLogin})> upsert({
    String? eatingPattern,
    String? preferencesJson,
    bool? allergiesAcknowledged,
    String? vietnamRegion,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (eatingPattern != null) body['eatingPattern'] = eatingPattern;
      if (preferencesJson != null) body['preferences'] = preferencesJson;
      if (allergiesAcknowledged != null) {
        body['allergiesAcknowledged'] = allergiesAcknowledged;
      }
      if (vietnamRegion != null) body['vietnamRegion'] = vietnamRegion;

      final response = await _api.putJson(ApiEndpoints.userAiProfileMe, body);
      if (response.statusCode == 200) {
        return (
          success: true,
          message: 'Đã lưu sở thích',
          requiresLogin: false,
        );
      }
      if (response.statusCode == 401) {
        return (
          success: false,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          requiresLogin: true,
        );
      }
      if (response.statusCode == 403) {
        return (
          success: false,
          message: 'Tài khoản không có quyền cập nhật hồ sơ Office.',
          requiresLogin: false,
        );
      }
      return (
        success: false,
        message: _errorMessage(response.body),
        requiresLogin: false,
      );
    } catch (_) {
      return (
        success: false,
        message: 'Không thể kết nối đến máy chủ',
        requiresLogin: false,
      );
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
