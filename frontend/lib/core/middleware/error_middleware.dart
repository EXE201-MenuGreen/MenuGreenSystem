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
  }) async {
    final stopwatch = Stopwatch()..start();
    logger.logRequest(method, uri);

    try {
      final response = await request();
      stopwatch.stop();
      logger.logResponse(method, uri, response.statusCode, stopwatch.elapsed);
      return response;
    } on TimeoutException catch (error) {
      stopwatch.stop();
      logger.logError(method, uri, error, stopwatch.elapsed);
      throw ApiException(
        type: ApiErrorType.timeout,
        message: ErrorTranslator.timeout(),
        cause: error,
      );
    } on http.ClientException catch (error) {
      stopwatch.stop();
      logger.logError(method, uri, error, stopwatch.elapsed);
      throw ApiException(
        type: ApiErrorType.noInternet,
        message: ErrorTranslator.networkUnavailable(),
        cause: error,
      );
    } catch (error) {
      stopwatch.stop();
      logger.logError(method, uri, error, stopwatch.elapsed);
      if (error.runtimeType.toString().contains('SocketException')) {
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

  static String messageForResponse(http.Response response) {
    return ErrorTranslator.fromStatusCode(
      response.statusCode,
      serverMessage: extractServerMessage(response.body),
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
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final direct = decoded['message'] ?? decoded['Message'];
        if (direct != null) return direct.toString();
        final error = decoded['error'] ?? decoded['Error'];
        if (error != null) return error.toString();
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
