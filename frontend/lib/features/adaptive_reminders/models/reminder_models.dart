class ReminderProfile {
  const ReminderProfile({
    required this.optimalBreakfastTime,
    required this.optimalLunchTime,
    required this.optimalDinnerTime,
    this.lastRecalculatedAt,
  });

  final String optimalBreakfastTime;
  final String optimalLunchTime;
  final String optimalDinnerTime;
  final DateTime? lastRecalculatedAt;

  ReminderProfile copyWith({
    String? optimalBreakfastTime,
    String? optimalLunchTime,
    String? optimalDinnerTime,
    DateTime? lastRecalculatedAt,
  }) =>
      ReminderProfile(
        optimalBreakfastTime: optimalBreakfastTime ?? this.optimalBreakfastTime,
        optimalLunchTime: optimalLunchTime ?? this.optimalLunchTime,
        optimalDinnerTime: optimalDinnerTime ?? this.optimalDinnerTime,
        lastRecalculatedAt: lastRecalculatedAt ?? this.lastRecalculatedAt,
      );

  Map<String, dynamic> toJson() => {
        'optimalBreakfastTime': optimalBreakfastTime,
        'optimalLunchTime': optimalLunchTime,
        'optimalDinnerTime': optimalDinnerTime,
      };

  factory ReminderProfile.fromJson(Map<String, dynamic> json) => ReminderProfile(
        optimalBreakfastTime: _text(json, 'optimalBreakfastTime', '08:00'),
        optimalLunchTime: _text(json, 'optimalLunchTime', '12:00'),
        optimalDinnerTime: _text(json, 'optimalDinnerTime', '19:00'),
        lastRecalculatedAt: _date(json['lastRecalculatedAt'] ?? json['LastRecalculatedAt']),
      );
}

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.isEnabled,
    this.type,
    this.scheduledAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isEnabled;
  final String? type;
  final DateTime? scheduledAt;

  factory ScheduledReminder.fromJson(Map<String, dynamic> json) => ScheduledReminder(
        id: _text(json, 'id', ''),
        title: _text(json, 'title', 'Nhắc nhở'),
        body: _text(json, 'body', ''),
        isEnabled: json['isEnabled'] == true || json['IsEnabled'] == true,
        type: _nullable(json['type'] ?? json['Type']),
        scheduledAt: _date(json['scheduledAt'] ?? json['ScheduledAt']),
      );
}

String _text(Map<String, dynamic> json, String key, String fallback) =>
    (json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'] ?? fallback).toString();

String? _nullable(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
