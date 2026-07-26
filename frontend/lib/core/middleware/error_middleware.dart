import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'error_translator.dart';
import 'logging_middleware.dart';

enum ApiErrorType {
  noInternet,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  server,
  invalidData,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}

class ApiErrorMiddleware {
  ApiErrorMiddleware._();

  static Future<http.Response> guard({
    required String method,
    required Uri uri,
    required Future<http.Response> Function() request,
    required ApiLoggingMiddleware logger,
    int maxRetries = 3,
  }) async {
    final stopwatch = Stopwatch()..start();
    logger.logRequest(method, uri);

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await request();

        // Nếu server tạm thời quá tải/mất kết nối (502, 503, 504) và còn lượt thử
        if ((response.statusCode == 502 ||
                response.statusCode == 503 ||
                response.statusCode == 504) &&
            attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }

        stopwatch.stop();
        logger.logResponse(method, uri, response.statusCode, stopwatch.elapsed);
        return response;
      } on TimeoutException catch (error) {
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        stopwatch.stop();
        logger.logError(method, uri, error, stopwatch.elapsed);
        throw ApiException(
          type: ApiErrorType.timeout,
          message: ErrorTranslator.timeout(),
          cause: error,
        );
      } on http.ClientException catch (error) {
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        stopwatch.stop();
        logger.logError(method, uri, error, stopwatch.elapsed);
        throw ApiException(
          type: ApiErrorType.noInternet,
          message: ErrorTranslator.networkUnavailable(),
          cause: error,
        );
      } catch (error) {
        final isSocket = error.runtimeType.toString().contains('SocketException');
        if (attempt < maxRetries && isSocket) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        stopwatch.stop();
        logger.logError(method, uri, error, stopwatch.elapsed);
        if (isSocket) {
          throw ApiException(
            type: ApiErrorType.noInternet,
            message: ErrorTranslator.networkUnavailable(),
            cause: error,
          );
        }
        throw ApiException(
          type: ApiErrorType.unknown,
          message: 'Đã xảy ra lỗi khi kết nối đến máy chủ.',
          cause: error,
        );
      }
    }
  }

  static String messageForResponse(http.Response response) {
    return ErrorTranslator.fromStatusCode(
      response.statusCode,
      serverMessage: extractServerMessage(response.body),
    );
  }

  static http.Response responseFromException(ApiException error) {
    final statusCode = switch (error.type) {
      ApiErrorType.timeout => 408,
      ApiErrorType.noInternet => 503,
      ApiErrorType.badRequest => 400,
      ApiErrorType.unauthorized => 401,
      ApiErrorType.forbidden => 403,
      ApiErrorType.notFound => 404,
      ApiErrorType.rateLimited => 429,
      ApiErrorType.server => error.statusCode ?? 500,
      ApiErrorType.invalidData => 422,
      ApiErrorType.unknown => error.statusCode ?? 500,
    };

    return http.Response(
      jsonEncode({
        'message': error.message,
        'errorType': error.type.name,
      }),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }

  static ApiErrorType typeForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return ApiErrorType.badRequest;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 429:
        return ApiErrorType.rateLimited;
      default:
        return statusCode >= 500 ? ApiErrorType.server : ApiErrorType.unknown;
    }
  }

  static String? extractServerMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    // Khai tử hoàn toàn nội dung HTML nếu server trả về trang HTML 500/502/504
    final lower = trimmed.toLowerCase();
    if (lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('<body')) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        // Trích xuất lỗi Validation / ProblemDetails từ ASP.NET Core
        if (decoded.containsKey('errors') && decoded['errors'] is Map) {
          final errorsMap = decoded['errors'] as Map;
          if (errorsMap.isNotEmpty) {
            final firstVal = errorsMap.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              return firstVal.first.toString();
            }
            return firstVal.toString();
          }
        }
        final direct = decoded['message'] ??
            decoded['Message'] ??
            decoded['title'] ??
            decoded['Title'] ??
            decoded['detail'] ??
            decoded['Detail'] ??
            decoded['error'] ??
            decoded['Error'];
        if (direct != null && direct.toString().isNotEmpty) {
          return direct.toString();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static T requireData<T>(Object? value) {
    if (value is T) return value;
    throw ApiException(
      type: ApiErrorType.invalidData,
      message: ErrorTranslator.invalidData(),
    );
  }
}
