import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class NotificationSettings {
  NotificationSettings({
    required this.mealReminderEnabled,
    required this.mealReminderOffsetMinutes,
    required this.prepReminderEnabled,
    required this.prepReminderOffsetMinutes,
    required this.inAppEnabled,
    required this.pushEnabled,
  });

  final bool mealReminderEnabled;
  final int mealReminderOffsetMinutes;
  final bool prepReminderEnabled;
  final int prepReminderOffsetMinutes;
  final bool inAppEnabled;
  final bool pushEnabled;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      mealReminderEnabled:
          json['mealReminderEnabled'] == true || json['MealReminderEnabled'] == true,
      mealReminderOffsetMinutes: _int(
        json['mealReminderOffsetMinutes'] ?? json['MealReminderOffsetMinutes'],
        30,
      ),
      prepReminderEnabled:
          json['prepReminderEnabled'] == true || json['PrepReminderEnabled'] == true,
      prepReminderOffsetMinutes: _int(
        json['prepReminderOffsetMinutes'] ?? json['PrepReminderOffsetMinutes'],
        20,
      ),
      inAppEnabled: json['inAppEnabled'] == true || json['InAppEnabled'] == true,
      pushEnabled: json['pushEnabled'] == true || json['PushEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'mealReminderEnabled': mealReminderEnabled,
        'mealReminderOffsetMinutes': mealReminderOffsetMinutes,
        'prepReminderEnabled': prepReminderEnabled,
        'prepReminderOffsetMinutes': prepReminderOffsetMinutes,
        'inAppEnabled': inAppEnabled,
        'pushEnabled': pushEnabled,
      };
}

int _int(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.round();
  return fallback;
}

class NotificationRepository {
  NotificationRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<NotificationSettings?> getSettings() async {
    try {
      final response = await _api.get(ApiEndpoints.notificationSettings);
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return NotificationSettings.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<NotificationSettings?> updateSettings(NotificationSettings settings) async {
    try {
      final response =
          await _api.putJson(ApiEndpoints.notificationSettings, settings.toJson());
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return NotificationSettings.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
