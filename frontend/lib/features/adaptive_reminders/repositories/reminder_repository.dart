import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/reminder_models.dart';

class ReminderRepository {
  ReminderRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<ReminderProfile> getProfile() async =>
      ReminderProfile.fromJson(await _object(_api.get(ApiEndpoints.reminderProfile)));

  Future<ReminderProfile> updateProfile(ReminderProfile profile) async =>
      ReminderProfile.fromJson(await _object(_api.putJson(ApiEndpoints.reminderProfile, profile.toJson())));

  Future<ReminderProfile> recalculateProfile() async => ReminderProfile.fromJson(
        await _object(_api.postJson(ApiEndpoints.reminderProfileRecalculate, const {})),
      );

  Future<List<ScheduledReminder>> getScheduled() async {
    final response = await _api.get(ApiEndpoints.scheduledReminders);
    if (response.statusCode != 200 || response.body.isEmpty) throw Exception(_message(response));
    final data = jsonDecode(response.body);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => ScheduledReminder.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<ScheduledReminder> create({
    required String title,
    required String body,
    required DateTime scheduledAt,
    int? repeatIntervalMinutes,
  }) async =>
      ScheduledReminder.fromJson(await _object(_api.postJson(ApiEndpoints.scheduledReminders, {
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'type': 'CUSTOM_REMINDER',
        'repeatIntervalMinutes': ?repeatIntervalMinutes,
      })));

  Future<ScheduledReminder> update(
    String id, {
    String? title,
    String? body,
    DateTime? scheduledAt,
    bool? isEnabled,
  }) async =>
      ScheduledReminder.fromJson(await _object(_api.patchJson(ApiEndpoints.scheduledReminderById(id), {
        'title': ?title,
        'body': ?body,
        'scheduledAt': ?scheduledAt?.toUtc().toIso8601String(),
        'isEnabled': ?isEnabled,
      })));

  Future<ScheduledReminder> snooze(String id, int minutes) async {
    final uri = Uri.parse(ApiEndpoints.scheduledReminderSnooze(id))
        .replace(queryParameters: {'minutes': '$minutes'});
    return ScheduledReminder.fromJson(await _object(_api.postJson(uri.toString(), const {})));
  }

  Future<void> delete(String id) async {
    final response = await _api.delete(ApiEndpoints.scheduledReminderById(id));
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  Future<Map<String, dynamic>> _object(Future<dynamic> request) async {
    final response = await request;
    if ((response.statusCode != 200 && response.statusCode != 201) || response.body.isEmpty) {
      throw Exception(_message(response));
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) throw Exception('Phản hồi không hợp lệ.');
    return data;
  }

  String _message(dynamic response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) return (data['message'] ?? data['Message'] ?? 'Không thể thực hiện thao tác.').toString();
    } catch (_) {}
    return 'Không thể thực hiện thao tác.';
  }
}
