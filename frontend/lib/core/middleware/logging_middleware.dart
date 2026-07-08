import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class ApiLoggingMiddleware {
  const ApiLoggingMiddleware();

  void logRequest(String method, Uri uri) {
    if (!kDebugMode) return;
    developer.log('[API] -> $method ${_safeUri(uri)}', name: 'ApiClient');
  }

  void logResponse(
    String method,
    Uri uri,
    int statusCode,
    Duration elapsed,
  ) {
    if (!kDebugMode) return;
    developer.log(
      '[API] <- $method ${_safeUri(uri)} $statusCode ${elapsed.inMilliseconds}ms',
      name: 'ApiClient',
    );
  }

  void logError(String method, Uri uri, Object error, Duration elapsed) {
    if (!kDebugMode) return;
    developer.log(
      '[API] xx $method ${_safeUri(uri)} ${elapsed.inMilliseconds}ms $error',
      name: 'ApiClient',
    );
  }

  String _safeUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri.toString();

    final redacted = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.toLowerCase();
      final isSensitive = key.contains('token') ||
          key.contains('password') ||
          key.contains('otp') ||
          key.contains('secret');
      redacted[entry.key] = isSensitive ? '***' : entry.value;
    }
    return uri.replace(queryParameters: redacted).toString();
  }
}
