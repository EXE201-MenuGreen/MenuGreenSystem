import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/notifications/views/notification_inbox_screen.dart';
import '../../features/meal_plan/views/meal_plan_detail_screen.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/coach/views/coach_main_screen.dart';
import '../../features/coach_pt/views/coach_report_detail_screen.dart';
import '../../features/coach_pt/providers/coach_meal_plan_provider.dart';
import '../../features/coach_pt/views/coach_meal_plan_detail_screen.dart';
import '../../features/advanced/views/advanced_features_screen.dart';
import '../../features/gymer/views/premium_programs_screen.dart';
import '../../features/coach_chat/views/coach_chat_screen.dart';
import '../../features/notifications/models/notification_models.dart';
import '../../core/i18n/api_message_translator.dart';

enum NotificationActionType {
  openApp,
  openNotifications,
  openMealPlan,
  openRecipe,
  openProfile,
  openSubscription,
  openGymerPrograms,
  openCoachWorkspace,
  openCoachMealPlan,
  openCoachWeeklyReport,
  openGymerWeeklyReport,
  openCoachChat,
  custom,
}

class NotificationAction {
  final NotificationActionType type;
  final String? id;
  final String? deepLink;
  final int? tabIndex;
  final String? clientId;

  NotificationAction({
    required this.type,
    this.id,
    this.deepLink,
    this.tabIndex,
    this.clientId,
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
  static const String _prefixCoachWeeklyReport = 'coach_weekly_report:';
  static const String _prefixCoachRouteApproval = 'coach_route_approval:';
  static const String _prefixGymerWeeklyReport = 'gymer_weekly_report:';
  static const String _prefixGymerRouteApproval = 'gymer_route_approval:';
  static const String _prefixGymerPersonalProgram = 'gymer_personal_program:';
  static const String _prefixMealPlanProposal = 'meal_plan_proposal:';
  static const String _prefixCoachChat = 'chat:';

  NotificationAction parseNotificationData(Map<String, dynamic> data) {
    final deepLink =
        data['deepLink'] ??
        data['DeepLink'] ??
        data['actionUrl'] ??
        data['ActionUrl'] ??
        data['link'] ??
        data['url'];

    if (deepLink != null && deepLink is String && deepLink.isNotEmpty) {
      return _parseDeepLink(deepLink);
    }

    var type = data['type'] ?? data['Type'] ?? data['action'];
    dynamic notificationId = data['id'] ?? data['notificationId'];
    final customData = data['custom_data'] ?? data['customData'];
    if ((type == null || type.toString().isEmpty) &&
        customData is String &&
        customData.isNotEmpty) {
      final parts = customData.split('|');
      type = parts.first;
      if (parts.length > 1) notificationId = parts[1];
      if (parts.length > 2) {
        return _parseDeepLink(parts.sublist(2).join('|'));
      }
    }

    switch (type?.toString().toLowerCase()) {
      case 'weekly_report_submitted':
        return NotificationAction(
          type: NotificationActionType.openCoachWorkspace,
          id: notificationId?.toString(),
          tabIndex: 2,
        );
      case 'weekly_report_pending':
      case 'weekly_report_reviewed':
        return NotificationAction(
          type: NotificationActionType.openGymerWeeklyReport,
          id: data['reportId']?.toString(),
        );
      case 'midweek_plan_proposal':
      case 'next_week_plan_proposal':
      case 'meal_plan_proposal_deadline':
        return NotificationAction(
          type: NotificationActionType.openGymerWeeklyReport,
        );
      case 'meal_plan_approved':
      case 'pt_route_approval':
        return NotificationAction(
          type: NotificationActionType.openGymerPrograms,
          id: data['reportId']?.toString(),
          tabIndex: 0,
        );
      case 'coach_personal_program':
        return NotificationAction(
          type: NotificationActionType.openGymerPrograms,
          id: notificationId?.toString(),
          tabIndex: 1,
        );
      case 'pt_review_request':
        final clientId =
            data['clientId']?.toString() ?? data['ClientId']?.toString();
        final planId =
            data['planId']?.toString() ??
            data['PlanId']?.toString() ??
            data['mealPlanId']?.toString() ??
            data['MealPlanId']?.toString();
        if (clientId != null &&
            clientId.isNotEmpty &&
            planId != null &&
            planId.isNotEmpty) {
          return NotificationAction(
            type: NotificationActionType.openCoachMealPlan,
            clientId: clientId,
            id: planId,
          );
        }
        return NotificationAction(
          type: NotificationActionType.openCoachWorkspace,
          id: notificationId?.toString(),
          tabIndex: 1,
        );
      case 'coach_chat_message':
        return NotificationAction(
          type: NotificationActionType.openCoachChat,
          id:
              data['partnerId']?.toString() ??
              data['PartnerId']?.toString() ??
              data['senderId']?.toString() ??
              data['SenderId']?.toString(),
        );
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
        return NotificationAction(type: NotificationActionType.openProfile);
      default:
        return NotificationAction(type: NotificationActionType.openApp);
    }
  }

  NotificationAction _parseDeepLink(String deepLink) {
    if (deepLink.startsWith(_prefixCoachRouteApproval)) {
      final payload = deepLink.substring(_prefixCoachRouteApproval.length);
      final parts = payload.split(':');
      if (parts.length == 2 && parts.every((part) => part.isNotEmpty)) {
        return NotificationAction(
          type: NotificationActionType.openCoachMealPlan,
          clientId: parts[0],
          id: parts[1],
        );
      }
    }
    if (deepLink.startsWith(_prefixCoachWeeklyReport)) {
      final id = deepLink.substring(_prefixCoachWeeklyReport.length);
      return NotificationAction(
        type: NotificationActionType.openCoachWeeklyReport,
        id: id,
      );
    }
    if (deepLink.startsWith(_prefixCoachChat)) {
      final id = deepLink.substring(_prefixCoachChat.length);
      return NotificationAction(
        type: NotificationActionType.openCoachChat,
        id: id,
      );
    }
    if (deepLink.startsWith(_prefixGymerWeeklyReport)) {
      final id = deepLink.substring(_prefixGymerWeeklyReport.length);
      return NotificationAction(
        type: NotificationActionType.openGymerWeeklyReport,
        id: id,
      );
    }
    if (deepLink.startsWith(_prefixGymerRouteApproval)) {
      final id = deepLink.substring(_prefixGymerRouteApproval.length);
      return NotificationAction(
        type: NotificationActionType.openGymerPrograms,
        id: id,
        tabIndex: 0,
      );
    }
    if (deepLink.startsWith(_prefixGymerPersonalProgram)) {
      final id = deepLink.substring(_prefixGymerPersonalProgram.length);
      return NotificationAction(
        type: NotificationActionType.openGymerPrograms,
        id: id,
        tabIndex: 1,
      );
    }
    if (deepLink.startsWith(_prefixMealPlanProposal)) {
      return NotificationAction(
        type: NotificationActionType.openGymerWeeklyReport,
      );
    }
    if (deepLink.startsWith(_prefixMealPlan)) {
      final id = deepLink.substring(_prefixMealPlan.length);
      return NotificationAction(
        type: NotificationActionType.openMealPlan,
        id: id,
      );
    }
    if (deepLink.startsWith(_prefixRecipe)) {
      final id = deepLink.substring(_prefixRecipe.length);
      return NotificationAction(
        type: NotificationActionType.openRecipe,
        id: id,
      );
    }
    if (deepLink.startsWith(_prefixNotification)) {
      final id = deepLink.substring(_prefixNotification.length);
      return NotificationAction(
        type: NotificationActionType.openNotifications,
        id: id,
      );
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

    return NotificationAction(
      type: NotificationActionType.openApp,
      deepLink: deepLink,
    );
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
    NotificationAction action, [
    RemoteMessage? message,
  ]) {
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
          title: message?.notification?.title ?? 'Công thức',
          message:
              message?.notification?.body ??
              'Không tìm thấy thông tin công thức',
        );

      case NotificationActionType.openSubscription:
        return const _DefaultDestinationScreen(
          title: 'Gói dịch vụ',
          message: 'Quản lý gói đăng ký của bạn',
        );

      case NotificationActionType.openProfile:
        return const ProfileView();

      case NotificationActionType.openGymerPrograms:
        return PremiumProgramsScreen(
          initialTabIndex: action.tabIndex ?? 0,
          initialRequestId: action.id,
        );

      case NotificationActionType.openCoachWorkspace:
        return CoachMainScreen(initialIndex: action.tabIndex ?? 1);

      case NotificationActionType.openCoachMealPlan:
        if (action.clientId != null &&
            action.clientId!.isNotEmpty &&
            action.id != null &&
            action.id!.isNotEmpty) {
          return ChangeNotifierProvider(
            create: (_) =>
                CoachMealPlanProvider()..loadPlansForClient(action.clientId!),
            child: CoachMealPlanDetailScreen(planId: action.id!),
          );
        }
        return const CoachMainScreen(initialIndex: 1);

      case NotificationActionType.openCoachWeeklyReport:
        if (action.id != null && action.id!.isNotEmpty) {
          return CoachReportDetailScreen(reportId: action.id!);
        }
        return const CoachMainScreen(initialIndex: 2);

      case NotificationActionType.openGymerWeeklyReport:
        return AdvancedFeaturesScreen(
          gymerOnly: true,
          initialIndex: 0,
          initialReportId: action.id,
        );

      case NotificationActionType.openCoachChat:
        if (action.id != null && action.id!.isNotEmpty) {
          return CoachChatScreen(partnerId: action.id!);
        }
        return const _DefaultDestinationScreen(
          title: 'Tin nhắn với PT',
          message: 'Không tìm thấy cuộc trò chuyện.',
        );

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

  Future<bool> handleAppNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    final action = parseNotificationData({
      'type': notification.rawType,
      'id': notification.id,
      if (notification.actionUrl != null) 'deepLink': notification.actionUrl,
    });
    if (action.type == NotificationActionType.openApp) return false;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => buildDestinationScreen(action)));
    return true;
  }

  void showInAppNotification(BuildContext context, RemoteMessage message) {
    // Translate notification title/body if coming from backend (English).
    final title = ApiMessageTranslator.translateNotification(
      message.notification?.title,
    );
    final body = ApiMessageTranslator.translateNotification(
      message.notification?.body,
    );

    if (title.isEmpty && body.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  const _DefaultDestinationScreen({required this.title, required this.message});

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
