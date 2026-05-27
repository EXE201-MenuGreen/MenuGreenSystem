import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_endpoints.dart';
import 'jwt_utils.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
  })  : _http = httpClient ?? http.Client(),
        _storage = tokenStorage ?? TokenStorage();

  final http.Client _http;
  final TokenStorage _storage;

  Future<http.Response> get(String url) async {
    return _sendWithAuthRetry((headers) => _http.get(Uri.parse(url), headers: headers));
  }

  Future<http.Response> delete(String url) async {
    return _sendWithAuthRetry((headers) => _http.delete(Uri.parse(url), headers: headers));
  }

  Future<http.Response> putJson(String url, Map<String, dynamic> body) async {
    return _sendWithAuthRetry(
      (headers) => _http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> postJson(String url, Map<String, dynamic> body) async {
    return _sendWithAuthRetry(
      (headers) => _http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _sendWithAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    await _ensureFreshAccessToken();
    final headers = await _buildAuthHeaders();
    final res = await send(headers);
    if (res.statusCode != 401) return res;

    final refreshed = await _tryRefreshToken();
    if (!refreshed) return res;

    final headers2 = await _buildAuthHeaders();
    return send(headers2);
  }

  Future<Map<String, String>> _buildAuthHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await _http.post(
        Uri.parse(ApiEndpoints.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = (data['accessToken'] ?? data['AccessToken'])?.toString();
      final refresh = (data['refreshToken'] ?? data['RefreshToken'])?.toString();
      final fullName = (data['fullName'] ?? data['FullName'])?.toString();

      if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) return false;
      await _storage.saveTokens(accessToken: access, refreshToken: refresh, fullName: fullName);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureFreshAccessToken() async {
    final access = await _storage.getAccessToken();
    if (access == null || access.isEmpty) return;

    final exp = JwtUtils.tryGetExpiryEpochSeconds(access);
    if (exp == null) return;

    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    // Refresh early when token has <= 60s remaining
    if (exp - nowSec <= 60) {
      await _tryRefreshToken();
    }
  }
}

