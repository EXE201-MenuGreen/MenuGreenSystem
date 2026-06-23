import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:http/http.dart' as http;

import 'api_endpoints.dart';
import 'jwt_utils.dart';
import 'token_storage.dart';

/// HTTP client dùng chung — tránh refresh token trùng lặp khi nhiều tab gọi API cùng lúc.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    Duration? timeout,
  })  : _http = httpClient ?? http.Client(),
        _storage = tokenStorage ?? TokenStorage(),
        _timeout = timeout ?? const Duration(seconds: 20);

  final http.Client _http;
  final TokenStorage _storage;
  final Duration _timeout;

  static Completer<bool>? _refreshInFlight;
  static DateTime? _lastSuccessfulRefresh;

  Future<http.Response> get(String url) async {
    return _sendWithAuthRetry(
      (headers) => _http.get(Uri.parse(url), headers: headers).timeout(_timeout),
    );
  }

  Future<http.Response> delete(String url) async {
    return _sendWithAuthRetry(
      (headers) => _http.delete(Uri.parse(url), headers: headers).timeout(_timeout),
    );
  }

  Future<http.Response> deleteWithBody(String url, Map<String, dynamic> body) async {
    return _sendWithAuthRetry(
      (headers) => _http
          .delete(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout),
    );
  }

  Future<http.Response> putJson(String url, Map<String, dynamic> body) async {
    return _sendWithAuthRetry(
      (headers) => _http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout),
    );
  }

  Future<http.Response> patchJson(String url, Map<String, dynamic> body) async {
    return _sendWithAuthRetry(
      (headers) => _http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout),
    );
  }

  Future<http.Response> postJson(String url, Map<String, dynamic> body) async {
    return _sendWithAuthRetry(
      (headers) => _http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout),
    );
  }

  Future<http.Response> postMultipart(String url, List<int> fileBytes, String fieldName, String filename) async {
    return _sendWithAuthRetry((headers) async {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      
      // Copy headers
      request.headers.addAll(headers);
      
      // Add multipart file
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send().timeout(_timeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  Future<http.Response> _sendWithAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    await _ensureFreshAccessToken();
    final headers = await _buildAuthHeaders();
    print('[DEBUG] API Request headers: $headers');
    final res = await send(headers);
    print('[DEBUG] API Response status: ${res.statusCode}');
    print('[DEBUG] API Response body: ${res.body.substring(0, min(500, res.body.length))}');
    if (res.statusCode != 401) return res;

    final refreshed = await _refreshTokenOnce();
    if (!refreshed) return res;

    final headers2 = await _buildAuthHeaders();
    return send(headers2);
  }

  Future<Map<String, String>> _buildAuthHeaders() async {
    final token = await _storage.getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    // DEBUG: print token status
    print('[DEBUG] Token exists: ${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      print('[DEBUG] Token preview: ${token.substring(0, min(20, token.length))}...');
    }
    return headers;
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await _http
          .post(
            Uri.parse(ApiEndpoints.refreshToken),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) {
        print('[DEBUG] Refresh token failed: status ${res.statusCode}');
        return false;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = (data['accessToken'] ?? data['AccessToken'])?.toString();
      final refresh = (data['refreshToken'] ?? data['RefreshToken'])?.toString();
      final fullName = (data['fullName'] ?? data['FullName'])?.toString();

      if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
        return false;
      }
      await _storage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
        fullName: fullName,
      );
      _lastSuccessfulRefresh = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Chỉ một refresh chạy tại một thời điểm — các request khác chờ kết quả.
  Future<bool> _refreshTokenOnce() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!.future;
    }
    final completer = Completer<bool>();
    _refreshInFlight = completer;
    try {
      final ok = await _tryRefreshToken();
      completer.complete(ok);
      return ok;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _ensureFreshAccessToken() async {
    final access = await _storage.getAccessToken();
    if (access == null || access.isEmpty) return;

    final exp = JwtUtils.tryGetExpiryEpochSeconds(access);
    if (exp == null) return;

    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (exp - nowSec > 60) return;

    final last = _lastSuccessfulRefresh;
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 45)) {
      return;
    }

    await _refreshTokenOnce();
  }
}
