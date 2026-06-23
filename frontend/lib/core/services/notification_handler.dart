import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../features/notifications/views/notification_inbox_screen.dart';
import '../../features/meal_plan/views/meal_plan_detail_screen.dart';
import '../../features/profile/views/profile_view.dart';
import '../../core/i18n/api_message_translator.dart';

enum NotificationActionType {
  openApp,
  openNotifications,
  openMealPlan,
  openRecipe,
  openProfile,
  openSubscription,
  custom,
}

class NotificationAction {
  final NotificationActionType type;
  final String? id;
  final String? deepLink;

  NotificationAction({
    required this.type,
    this.id,
    this.deepLink,
  });
}

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  static const String _prefixMealPlan = 'meal_plan:';
  static const String _prefixRecipe = 'recipe:';
  static const String _prefixNotification = 'notification:';
  static const String _prefixSubscription = 'subscription:';
  static const String _prefixProfile = 'profile:';

  NotificationAction parseNotificationData(Map<String, dynamic> data) {
    final deepLink = data['deepLink'] ?? data['link'] ?? data['url'];

    if (deepLink != null && deepLink is String && deepLink.isNotEmpty) {
      return _parseDeepLink(deepLink);
    }

    final type = data['type'] ?? data['action'];

    switch (type?.toString().toLowerCase()) {
      case 'meal_plan':
      case 'mealplan':
        return NotificationAction(
          type: NotificationActionType.openMealPlan,
          id: data['id'] ?? data['planId'] ?? data['mealPlanId'],
        );
      case 'recipe':
        return NotificationAction(
          type: NotificationActionType.openRecipe,
          id: data['id'] ?? data['recipeId'],
        );
      case 'subscription':
      case 'renewal':
      case 'expiry':
        return NotificationAction(
          type: NotificationActionType.openSubscription,
        );
      case 'notification':
        return NotificationAction(
          type: NotificationActionType.openNotifications,
          id: data['id'],
        );
      case 'profile':
        return NotificationAction(
          type: NotificationActionType.openProfile,
        );
      default:
        return NotificationAction(type: NotificationActionType.openApp);
    }
  }

  NotificationAction _parseDeepLink(String deepLink) {
    if (deepLink.startsWith(_prefixMealPlan)) {
      final id = deepLink.substring(_prefixMealPlan.length);
      return NotificationAction(type: NotificationActionType.openMealPlan, id: id);
    }
    if (deepLink.startsWith(_prefixRecipe)) {
      final id = deepLink.substring(_prefixRecipe.length);
      return NotificationAction(type: NotificationActionType.openRecipe, id: id);
    }
    if (deepLink.startsWith(_prefixNotification)) {
      final id = deepLink.substring(_prefixNotification.length);
      return NotificationAction(type: NotificationActionType.openNotifications, id: id);
    }
    if (deepLink.startsWith(_prefixSubscription)) {
      return NotificationAction(type: NotificationActionType.openSubscription);
    }
    if (deepLink.startsWith(_prefixProfile)) {
      return NotificationAction(type: NotificationActionType.openProfile);
    }

    if (deepLink.contains('mealplan') || deepLink.contains('meal-plan')) {
      return NotificationAction(
        type: NotificationActionType.openMealPlan,
        id: _extractIdFromUrl(deepLink),
      );
    }
    if (deepLink.contains('recipe')) {
      return NotificationAction(
        type: NotificationActionType.openRecipe,
        id: _extractIdFromUrl(deepLink),
      );
    }
    if (deepLink.contains('notification')) {
      return NotificationAction(
        type: NotificationActionType.openNotifications,
        id: _extractIdFromUrl(deepLink),
      );
    }
    if (deepLink.contains('subscription') || deepLink.contains('premium')) {
      return NotificationAction(type: NotificationActionType.openSubscription);
    }

    return NotificationAction(type: NotificationActionType.openApp, deepLink: deepLink);
  }

  String? _extractIdFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return null;

    final lastSegment = pathSegments.last;
    if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(lastSegment)) {
      return lastSegment;
    }
    if (RegExp(r'^\d+$').hasMatch(lastSegment)) {
      return lastSegment;
    }

    return uri.queryParameters['id'] ??
        uri.queryParameters['planId'] ??
        uri.queryParameters['recipeId'];
  }

  Future<void> handleNotificationTap(
    BuildContext context,
    RemoteMessage message,
  ) async {
    final data = message.data;
    final action = parseNotificationData(data);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => buildDestinationScreen(action, message),
      ),
    );
  }

  Widget buildDestinationScreen(
    NotificationAction action,
    RemoteMessage message,
  ) {
    switch (action.type) {
      case NotificationActionType.openNotifications:
        return const NotificationInboxScreen();

      case NotificationActionType.openMealPlan:
        if (action.id != null) {
          return MealPlanDetailScreen(planId: action.id!);
        }
        return const _DefaultDestinationScreen(
          title: 'Kế hoạch ăn uống',
          message: 'Không tìm thấy thông tin kế hoạch',
        );

      case NotificationActionType.openRecipe:
        return _DefaultDestinationScreen(
          title: message.notification?.title ?? 'Công thức',
          message: message.notification?.body ?? 'Không tìm thấy thông tin công thức',
        );

      case NotificationActionType.openSubscription:
        return const _DefaultDestinationScreen(
          title: 'Gói dịch vụ',
          message: 'Quản lý gói đăng ký của bạn',
        );

      case NotificationActionType.openProfile:
        return const ProfileView();

      case NotificationActionType.custom:
        return const _DefaultDestinationScreen(
          title: 'MenuGreen',
          message: 'Đã nhận thông báo mới',
        );

      case NotificationActionType.openApp:
        return const _DefaultDestinationScreen(
          title: 'MenuGreen',
          message: 'Đã nhận thông báo mới',
        );
    }
  }

  void showInAppNotification(
    BuildContext context,
    RemoteMessage message,
  ) {
    // Translate notification title/body if coming from backend (English).
    final title = ApiMessageTranslator.translateNotification(message.notification?.title);
    final body = ApiMessageTranslator.translateNotification(message.notification?.body);

    if (title.isEmpty && body.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () => handleNotificationTap(context, message),
        ),
      ),
    );
  }
}

class _DefaultDestinationScreen extends StatelessWidget {
  final String title;
  final String message;

  const _DefaultDestinationScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
