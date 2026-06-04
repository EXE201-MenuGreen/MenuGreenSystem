import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class OnboardingRepository {
  OnboardingRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<({bool success, String message, Map<String, dynamic>? data})> complete({
    int? targetCalories,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (targetCalories != null) body['targetCalories'] = targetCalories;

      final response = await _api.postJson(
        ApiEndpoints.onboardingComplete,
        body.isEmpty ? {} : body,
      );

      if (response.statusCode == 200) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return (
          success: true,
          message: 'Thiết lập hoàn tất',
          data: decoded is Map<String, dynamic> ? decoded : null,
        );
      }
      return (
        success: false,
        message: _errorMessage(response.body),
        data: null,
      );
    } catch (_) {
      return (
        success: false,
        message: 'Không thể kết nối đến máy chủ',
        data: null,
      );
    }
  }

  String _errorMessage(String body) {
    if (body.isEmpty) return 'Hoàn tất thiết lập thất bại';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['Message'];
        if (message != null) return message.toString();
      }
    } catch (_) {}
    return 'Hoàn tất thiết lập thất bại';
  }
}
