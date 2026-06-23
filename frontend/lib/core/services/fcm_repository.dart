import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class FcmRepository {
  FcmRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<DeviceTokenResponse?> registerToken({
    required String token,
    String? deviceType,
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.fcmRegister,
        {
          'token': token,
          'deviceType': deviceType,
          'deviceName': deviceName,
          'appVersion': appVersion,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return DeviceTokenResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> removeToken(String token) async {
    try {
      final response = await _api.deleteWithBody(
        ApiEndpoints.fcmRemove,
        {'token': token},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<DeviceTokenResponse>> getUserTokens() async {
    try {
      final response = await _api.get(ApiEndpoints.fcmTokens);
      if (response.statusCode != 200) return [];
      
      final decoded = jsonDecode(response.body);
      final items = decoded is List ? decoded : (decoded['items'] ?? []);
      return (items as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => DeviceTokenResponse.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendToSelf({
    required String title,
    required String body,
    String? data,
  }) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.fcmSend,
        {
          'title': title,
          'body': body,
          'data': data,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;
}

class DeviceTokenResponse {
  final String id;
  final String token;
  final String? deviceType;
  final String? deviceName;
  final String? appVersion;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  DeviceTokenResponse({
    required this.id,
    required this.token,
    this.deviceType,
    this.deviceName,
    this.appVersion,
    required this.isActive,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory DeviceTokenResponse.fromJson(Map<String, dynamic> json) {
    return DeviceTokenResponse(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      token: (json['token'] ?? json['Token'] ?? '').toString(),
      deviceType: (json['deviceType'] ?? json['DeviceType'])?.toString(),
      deviceName: (json['deviceName'] ?? json['DeviceName'])?.toString(),
      appVersion: (json['appVersion'] ?? json['AppVersion'])?.toString(),
      isActive: json['isActive'] == true || json['IsActive'] == true,
      createdAt: _parseDateTime(json['createdAt'] ?? json['CreatedAt']),
      lastUsedAt: json['lastUsedAt'] != null || json['LastUsedAt'] != null
          ? _parseDateTime(json['lastUsedAt'] ?? json['LastUsedAt'])
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
