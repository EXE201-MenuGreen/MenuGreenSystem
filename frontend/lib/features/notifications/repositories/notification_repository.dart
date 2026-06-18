import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/notification_models.dart';

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

  Future<List<AppNotification>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.notifications}?page=$page&pageSize=$pageSize',
      );
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      final items = decoded is List ? decoded : (decoded['items'] ?? decoded['data'] ?? []);
      return (items as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AppNotification?> getNotificationById(String id) async {
    try {
      final response = await _api.get(ApiEndpoints.notificationById(id));
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return AppNotification.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get(ApiEndpoints.notificationUnreadCount);
      if (response.statusCode != 200) return 0;
      final decoded = jsonDecode(response.body);
      return decoded['count'] ?? decoded['unreadCount'] ?? decoded['unread_count'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _api.patch(ApiEndpoints.notificationMarkRead(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _api.patch(ApiEndpoints.notificationMarkAllRead);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _api.delete(ApiEndpoints.notificationDelete(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> trackOpen(String id) async {
    try {
      final response = await _api.post(ApiEndpoints.notificationTrackOpen(id), {});
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> trackClick(String id) async {
    try {
      final response = await _api.post(ApiEndpoints.notificationTrackClick(id), {});
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<NotificationAnalytics?> getAnalytics() async {
    try {
      final response = await _api.get(ApiEndpoints.notificationAnalytics);
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return NotificationAnalytics.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }
}
