import 'dart:convert';
import '../../../core/middleware/error_middleware.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/jwt_utils.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/firebase_google_auth_service.dart';
import '../utils/auth_error_messages.dart';

class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    FirebaseGoogleAuthService? googleAuthService,
  })  : _api = apiClient ?? ApiClient(tokenStorage: tokenStorage),
        _storage = tokenStorage ?? TokenStorage(),
        _googleAuth = googleAuthService ?? FirebaseGoogleAuthService();

  final ApiClient _api;
  final TokenStorage _storage;
  final FirebaseGoogleAuthService _googleAuth;

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.forgotPassword,
        {'email': email},
        authenticated: false,
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
        'message': _errorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.resetPassword,
        {
          'email': email,
          'otpCode': otpCode,
          'newPassword': newPassword,
        },
        authenticated: false,
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
        'message': _errorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final idToken = await _googleAuth.signInAndGetIdToken();

      final response = await _api.postJson(
        ApiEndpoints.googleLogin,
        {'idToken': idToken},
        authenticated: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _maybePersistTokens(data);
        return {'success': true, 'data': data};
      }

      final error = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      return {
        'success': false,
        'message': localizeAuthMessage(
          extractApiMessage(error),
          fallback: 'Đăng nhập Google thất bại.',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': localizeAuthMessage(
          e.toString().replaceFirst('Exception: ', ''),
          fallback: 'Đăng nhập Google thất bại.',
        ),
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.login,
        {'email': email, 'password': password},
        authenticated: false,
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
        'message': _errorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.register,
        {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
        authenticated: false,
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
        'message': _errorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otpCode) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.verifyOtp,
        {'email': email, 'otpCode': otpCode},
        authenticated: false,
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
        'message': _errorMessage(e),
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

      final response = await _api.postJson(
        ApiEndpoints.refreshToken,
        {'refreshToken': refresh},
        authenticated: false,
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
        'message': _errorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    await _googleAuth.signOut();
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _storage.clear();
        return {'success': true, 'message': 'Logged out'};
      }

      final response = await _api.postJson(
        ApiEndpoints.logout,
        {'refreshToken': refresh},
        authenticated: false,
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
        'message': _errorMessage(e),
      };
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return localizeAuthMessage('Connection error. Is backend running?');
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

    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return;
    }
    await _storage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      fullName: fullName,
      userId: userId,
    );
  }
}
