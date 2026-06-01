import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/jwt_utils.dart';
import '../../../core/network/token_storage.dart';
import '../utils/auth_error_messages.dart';

class AuthRepository {
  AuthRepository({TokenStorage? tokenStorage})
    : _storage = tokenStorage ?? TokenStorage();

  final TokenStorage _storage;

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200) {
        return {'success': true, 'data': decoded};
      }

      return {
        'success': false,
        'message': localizeAuthMessage(
          extractApiMessage(decoded),
          fallback: 'Gửi yêu cầu quên mật khẩu thất bại.',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': localizeAuthMessage('Connection error. Is backend running?'),
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otpCode': otpCode,
          'newPassword': newPassword,
        }),
      );

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200) {
        return {'success': true, 'data': decoded};
      }

      return {
        'success': false,
        'message': localizeAuthMessage(
          extractApiMessage(decoded),
          fallback: 'Đặt lại mật khẩu thất bại.',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': localizeAuthMessage('Connection error. Is backend running?'),
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _maybePersistTokens(data);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': localizeAuthMessage(
            extractApiMessage(error),
            fallback: 'Đăng nhập thất bại.',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': localizeAuthMessage('Connection error. Is backend running?'),
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.clear();
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': localizeAuthMessage(
            extractApiMessage(error),
            fallback: 'Đăng ký thất bại.',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': localizeAuthMessage('Connection error. Is backend running?'),
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otpCode': otpCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': localizeAuthMessage(
            extractApiMessage(error),
            fallback: 'Xác thực OTP thất bại.',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': localizeAuthMessage('Connection error. Is backend running?'),
      };
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        return {
          'success': false,
          'message': localizeAuthMessage('No refresh token'),
        };
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _maybePersistTokens(data);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': localizeAuthMessage(
            extractApiMessage(error),
            fallback: 'Làm mới phiên đăng nhập thất bại.',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': localizeAuthMessage('Connection error. Is backend running?'),
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _storage.clear();
        return {'success': true, 'message': 'Logged out'};
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.logout),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );

      await _storage.clear();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        // Even if backend logout fails, local session is cleared
        return {
          'success': false,
          'message': localizeAuthMessage('Logout request failed'),
        };
      }
    } catch (e) {
      await _storage.clear();
      return {
        'success': false,
        'message': localizeAuthMessage('Connection error. Is backend running?'),
      };
    }
  }

  Future<void> _maybePersistTokens(dynamic decodedJson) async {
    if (decodedJson is! Map<String, dynamic>) return;
    final access = (decodedJson['accessToken'] ?? decodedJson['AccessToken'])
        ?.toString();
    final refresh = (decodedJson['refreshToken'] ?? decodedJson['RefreshToken'])
        ?.toString();
    final fullName = (decodedJson['fullName'] ?? decodedJson['FullName'])
        ?.toString();
    var userId = (decodedJson['userId'] ?? decodedJson['UserId'])?.toString();
    if (userId == null || userId.isEmpty) {
      userId = access != null ? JwtUtils.tryGetUserId(access) : null;
    }

    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty)
      return;
    await _storage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      fullName: fullName,
      userId: userId,
    );
  }
}
