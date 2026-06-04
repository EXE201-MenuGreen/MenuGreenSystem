import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../auth/repositories/auth_repository.dart';

class ProfileRepository {
  ProfileRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    AuthRepository? authRepository,
  })  : _api = apiClient ?? ApiClient(tokenStorage: tokenStorage),
        _storage = tokenStorage ?? TokenStorage(),
        _authRepoOverride = authRepository;

  final ApiClient _api;
  final TokenStorage _storage;
  final AuthRepository? _authRepoOverride;
  AuthRepository? _authRepoLazy;

  AuthRepository get _authRepo =>
      _authRepoOverride ?? (_authRepoLazy ??= AuthRepository(tokenStorage: _storage));

  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final response = await _api.get(ApiEndpoints.getProfile);

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
      final response = await _api.putJson(ApiEndpoints.getProfile, data);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final fullName = (body['fullName'] ?? body['FullName'])?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          await _storage.saveFullName(fullName);
        }
        return body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateAvatar(String avatarUrl) async {
    try {
      final response = await _api.putJson(ApiEndpoints.updateAvatar, {'avatarUrl': avatarUrl});
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> removeAvatar() async {
    try {
      final response = await _api.delete(ApiEndpoints.removeAvatar);
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
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) return {'success': false, 'message': 'Not logged in'};

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
    await _authRepo.logout();
  }
}
