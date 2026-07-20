import 'dart:convert';

import '../../../core/constants/health_profile_values.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class HealthProfileRepository {
  HealthProfileRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>?> getMyHealthProfile() async {
    try {
      final response = await _api.get(ApiEndpoints.healthProfileMe);
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<({bool success, String message, Map<String, dynamic>? data})>
  updateMyHealthProfile({
    required double heightCm,
    required double weightKg,
    double? bodyFatPercent,
    double? targetWeightKg,
    required String activityLevel,
    required String goal,
    int? targetCalories,
  }) async {
    try {
      final payload = <String, dynamic>{
        'heightCm': heightCm,
        'weightKg': weightKg,
        'bodyFatPercent': bodyFatPercent,
        'targetWeightKg': targetWeightKg,
        'activityLevel': HealthProfileValues.normalizeActivity(activityLevel),
        'goal': HealthProfileValues.normalizeGoal(goal),
      };
      if (targetCalories != null) payload['targetCalories'] = targetCalories;

      final response = await _api.putJson(
        ApiEndpoints.healthProfileMe,
        payload,
      );

      if (response.statusCode == 200) {
        final decoded = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        return (
          success: true,
          message: 'Lưu hồ sơ sức khỏe thành công',
          data: decoded is Map<String, dynamic> ? decoded : null,
        );
      }

      return (
        success: false,
        message: _extractErrorMessage(response.body),
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

  String _extractErrorMessage(String body) {
    if (body.isEmpty) return 'Cập nhật hồ sơ sức khỏe thất bại';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['Message'];
        if (message != null) return message.toString();
      }
    } catch (_) {}
    return 'Cập nhật hồ sơ sức khỏe thất bại';
  }
}
