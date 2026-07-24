import '../../../core/i18n/api_message_translator.dart';

enum NotificationType {
  mealReminder,
  prepReminder,
  subscription,
  weightReminder,
  mealLogReminder,
  system,
  achievement,
  tip,
  other,
}

extension NotificationTypeExtension on NotificationType {
  static NotificationType fromString(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('meal') && t.contains('remind')) return NotificationType.mealReminder;
    if (t.contains('prep')) return NotificationType.prepReminder;
    if (t.contains('subscription') || t.contains('expir')) return NotificationType.subscription;
    if (t.contains('weight') || t.contains('scale')) return NotificationType.weightReminder;
    if (t.contains('log') || t.contains('track')) return NotificationType.mealLogReminder;
    if (t.contains('system') || t.contains('maintenance')) return NotificationType.system;
    if (t.contains('achievement') || t.contains('badge')) return NotificationType.achievement;
    if (t.contains('tip') || t.contains('suggest')) return NotificationType.tip;
    return NotificationType.other;
  }

  String get label {
    switch (this) {
      case NotificationType.mealReminder:
        return 'Nhắc giờ ăn';
      case NotificationType.prepReminder:
        return 'Nhắc chuẩn bị';
      case NotificationType.subscription:
        return 'Gói dịch vụ';
      case NotificationType.weightReminder:
        return 'Nhắc cân';
      case NotificationType.mealLogReminder:
        return 'Nhắc ghi nhật ký';
      case NotificationType.system:
        return 'Hệ thống';
      case NotificationType.achievement:
        return 'Thành tựu';
      case NotificationType.tip:
        return 'Mẹo';
      case NotificationType.other:
        return 'Thông báo';
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl;
  final String? actionLabel;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.actionUrl,
    this.actionLabel,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      body: (json['body'] ?? json['Body'] ?? json['message'] ?? json['Message'] ?? '').toString(),
      type: NotificationTypeExtension.fromString(json['type'] ?? json['Type']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['CreatedAt'] ?? json['createdAt']),
      isRead: json['isRead'] == true || json['IsRead'] == true || json['isRead'] == 'true',
      actionUrl: (json['actionUrl'] ?? json['ActionUrl'])?.toString(),
      actionLabel: (json['actionLabel'] ?? json['ActionLabel'])?.toString(),
      metadata: json['metadata'] ?? json['Metadata'],
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

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? actionUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      metadata: metadata ?? this.metadata,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }

  String get displayTitle =>
      ApiMessageTranslator.translateNotification(title);
  String get displayBody =>
      ApiMessageTranslator.translateNotification(body);
}

class NotificationAnalytics {
  final int totalSent;
  final int totalOpened;
  final int totalClicked;
  final int totalActionCompleted;
  final double openRate;
  final double clickRate;
  final double actionCompletionRate;

  NotificationAnalytics({
    required this.totalSent,
    required this.totalOpened,
    required this.totalClicked,
    required this.totalActionCompleted,
    required this.openRate,
    required this.clickRate,
    required this.actionCompletionRate,
  });

  factory NotificationAnalytics.fromJson(Map<String, dynamic> json) {
    return NotificationAnalytics(
      totalSent: _int(json['totalSent'] ?? json['TotalSent'] ?? 0),
      totalOpened: _int(json['totalOpened'] ?? json['TotalOpened'] ?? 0),
      totalClicked: _int(json['totalClicked'] ?? json['TotalClicked'] ?? 0),
      totalActionCompleted: _int(json['totalActionCompleted'] ?? json['TotalActionCompleted'] ?? 0),
      openRate: (json['openRate'] ?? json['OpenRate'] ?? 0).toDouble(),
      clickRate: (json['clickRate'] ?? json['ClickRate'] ?? 0).toDouble(),
      actionCompletionRate: (json['actionCompletionRate'] ?? json['ActionCompletionRate'] ?? 0).toDouble(),
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return 0;
  }
}

class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final bool isEnabled;

  NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
  });

  factory NotificationChannel.fromJson(Map<String, dynamic> json) {
    return NotificationChannel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      isEnabled: json['isEnabled'] == true || json['IsEnabled'] == true,
    );
  }
}
