import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'push_notification_service.dart';
import 'notification_handler.dart';

class PushNotificationProvider extends ChangeNotifier {
  static final PushNotificationProvider _instance = PushNotificationProvider._internal();
  factory PushNotificationProvider() => _instance;
  PushNotificationProvider._internal();

  final PushNotificationService _service = PushNotificationService();
  final NotificationHandler _handler = NotificationHandler();

  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _fcmToken;
  String? _error;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  String? get fcmToken => _fcmToken;
  String? get error => _error;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    _isInitialized = await _service.initialize(
      onForegroundMessage: (message) => _handleForegroundMessage(context, message),
      onNotificationTap: (message, deepLink) => _handleNotificationTap(context, message),
    );

    if (_isInitialized) {
      _fcmToken = await _service.getFcmToken();
    }

    _hasPermission = _isInitialized;
    notifyListeners();
  }

  Future<void> registerToken() async {
    if (!_isInitialized) return;
    await _service.registerTokenWithBackend();
  }

  void _handleForegroundMessage(BuildContext context, RemoteMessage message) {
    debugPrint('[PushNotificationProvider] Foreground message: ${message.messageId}');
    if (context.mounted) {
      _handler.showInAppNotification(context, message);
    }
  }

  void _handleNotificationTap(BuildContext context, RemoteMessage message) {
    debugPrint('[PushNotificationProvider] Notification tap: ${message.messageId}');
    if (context.mounted) {
      _handler.handleNotificationTap(context, message);
    }
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
