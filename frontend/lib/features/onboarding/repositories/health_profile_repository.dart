import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class HealthProfileRepository {
  HealthProfileRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

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

  Future<({bool success, String message, Map<String, dynamic>? data})> updateMyHealthProfile({
    required double heightCm,
    required double weightKg,
    double? bodyFatPercent,
    required String activityLevel,
    required String goal,
  }) async {
    try {
      final response = await _api.putJson(ApiEndpoints.healthProfileMe, {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'bodyFatPercent': bodyFatPercent,
        'activityLevel': _normalizeActivityLevel(activityLevel),
        'goal': _normalizeGoal(goal),
      });

      if (response.statusCode == 200) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
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

  String _normalizeActivityLevel(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'light':
      case 'lightly active':
        return 'lightly active';
      case 'moderate':
      case 'moderately active':
        return 'moderately active';
      case 'active':
      case 'veryactive':
      case 'very active':
        return 'very active';
      default:
        return 'sedentary';
    }
  }

  String _normalizeGoal(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'loseweight':
      case 'lose weight':
        return 'lose weight';
      case 'gainweight':
      case 'gain weight':
        return 'gain weight';
      case 'buildmuscle':
      case 'build muscle':
        return 'build muscle';
      default:
        return 'maintain weight';
    }
  }
}
