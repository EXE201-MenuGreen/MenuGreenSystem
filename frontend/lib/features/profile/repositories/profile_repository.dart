import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_endpoints.dart';

class ProfileRepository {
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiEndpoints.getProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateMyProfile(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return null;

      final response = await http.put(
        Uri.parse(ApiEndpoints.getProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword, String confirmNewPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.put(
        Uri.parse(ApiEndpoints.changePassword),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Đổi mật khẩu thành công'};
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = error['message'] ?? 'Đổi mật khẩu thất bại';
        
        // Translate known backend errors
        if (errorMessage.contains('Current password is incorrect')) {
          errorMessage = 'Mật khẩu hiện tại không chính xác.';
        } else if (errorMessage.contains('New password must be different')) {
          errorMessage = 'Mật khẩu mới phải khác mật khẩu hiện tại.';
        } else if (errorMessage.contains('User not found')) {
          errorMessage = 'Tài khoản không tồn tại.';
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}
