import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../middleware/error_middleware.dart';
import '../middleware/logging_middleware.dart';
import 'api_endpoints.dart';
import 'jwt_utils.dart';
import 'token_storage.dart';

/// Shared HTTP client. It keeps auth refresh, timeout, logging and transport
/// error handling in one place so repositories do not duplicate that logic.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    Duration? timeout,
    ApiLoggingMiddleware? logger,
  })  : _http = httpClient ?? http.Client(),
        _storage = tokenStorage ?? TokenStorage(),
        _timeout = timeout ?? const Duration(seconds: 20),
        _logger = logger ?? const ApiLoggingMiddleware();

  final http.Client _http;
  final TokenStorage _storage;
  final Duration _timeout;
  final ApiLoggingMiddleware _logger;

  static Completer<bool>? _refreshInFlight;
  static DateTime? _lastSuccessfulRefresh;

  Future<http.Response> get(String url, {bool authenticated = true}) {
    final uri = Uri.parse(url);
    return _sendWithAuthRetry(
      method: 'GET',
      uri: uri,
      authenticated: authenticated,
      send: (headers) => _http.get(uri, headers: headers).timeout(_timeout),
    );
  }

  Future<http.Response> delete(String url, {bool authenticated = true}) {
    final uri = Uri.parse(url);
    return _sendWithAuthRetry(
      method: 'DELETE',
      uri: uri,
      authenticated: authenticated,
      send: (headers) => _http.delete(uri, headers: headers).timeout(_timeout),
    );
  }

  Future<http.Response> deleteWithBody(
    String url,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) {
    final uri = Uri.parse(url);
    return _sendWithAuthRetry(
      method: 'DELETE',
      uri: uri,
      authenticated: authenticated,
      send: (headers) => _http
          .delete(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout),
    );
  }

  Future<http.Response> putJson(
    String url,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) {
    final uri = Uri.parse(url);
    return _sendWithAuthRetry(
      method: 'PUT',
      uri: uri,
      authenticated: authenticated,
      send: (headers) => _http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout),
    );
  }

  Future<http.Response> patchJson(
    String url,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) {
    final uri = Uri.parse(url);
    return _sendWithAuthRetry(
      method: 'PATCH',
      uri: uri,
      authenticated: authenticated,
      send: (headers) => _http
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout),
    );
  }

  Future<http.Response> postJson(
    String url,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) {
    final uri = Uri.parse(url);
    return _sendWithAuthRetry(
      method: 'POST',
      uri: uri,
      authenticated: authenticated,
      send: (headers) => _http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout),
    );
  }

  Future<http.Response> postMultipart(
    String url,
    List<int> fileBytes,
    String fieldName,
    String filename, {
    bool authenticated = true,
  }) {
    final uri = Uri.parse(url);
    return _sendWithAuthRetry(
      method: 'POST',
      uri: uri,
      authenticated: authenticated,
      jsonContentType: false,
      send: (headers) async {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            fileBytes,
            filename: filename,
          ),
        );
        final streamedResponse = await request.send().timeout(_timeout);
        return http.Response.fromStream(streamedResponse);
      },
    );
  }

  Future<http.Response> _sendWithAuthRetry({
    required String method,
    required Uri uri,
    required bool authenticated,
    required Future<http.Response> Function(Map<String, String> headers) send,
    bool jsonContentType = true,
  }) async {
    if (authenticated) await _ensureFreshAccessToken();

    final headers = await _buildHeaders(
      authenticated: authenticated,
      jsonContentType: jsonContentType,
    );
    final response = await _guardedRequest(
      method: method,
      uri: uri,
      request: () => send(headers),
    );

    if (!authenticated || response.statusCode != 401) return response;

    final refreshed = await _refreshTokenOnce();
    if (!refreshed) return response;

    final retryHeaders = await _buildHeaders(
      authenticated: true,
      jsonContentType: jsonContentType,
    );
    return _guardedRequest(
      method: method,
      uri: uri,
      request: () => send(retryHeaders),
    );
  }

  Future<http.Response> _guardedRequest({
    required String method,
    required Uri uri,
    required Future<http.Response> Function() request,
  }) async {
    try {
      return await ApiErrorMiddleware.guard(
        method: method,
        uri: uri,
        logger: _logger,
        request: request,
      );
    } on ApiException catch (error) {
      return ApiErrorMiddleware.responseFromException(error);
    }
  }

  Future<Map<String, String>> _buildHeaders({
    required bool authenticated,
    required bool jsonContentType,
  }) async {
    final token = authenticated ? await _storage.getAccessToken() : null;
    return {
      if (jsonContentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = Uri.parse(ApiEndpoints.refreshToken);
      final response = await ApiErrorMiddleware.guard(
        method: 'POST',
        uri: uri,
        logger: _logger,
        request: () => _http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': refreshToken}),
            )
            .timeout(_timeout),
      );
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = (data['accessToken'] ?? data['AccessToken'])?.toString();
      final refresh = (data['refreshToken'] ?? data['RefreshToken'])?.toString();
      final fullName = (data['fullName'] ?? data['FullName'])?.toString();

      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
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

  Future<bool> _refreshTokenOnce() async {
    if (_refreshInFlight != null) return _refreshInFlight!.future;

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
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 45)) {
      return;
    }

    await _refreshTokenOnce();
  }
}
