import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_repository.dart';

typedef NotificationCallback = void Function(RemoteMessage message);
typedef NotificationTapCallback =
    void Function(RemoteMessage message, String? deepLink);

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FcmRepository _fcmRepository = FcmRepository();

  NotificationCallback? _onForegroundMessage;
  NotificationTapCallback? _onNotificationTap;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _isInitialized = false;

  Future<bool> initialize({
    NotificationCallback? onForegroundMessage,
    NotificationTapCallback? onNotificationTap,
  }) async {
    // Callers may move from Login -> Gymer/Coach workspace. Always refresh
    // callbacks so a notification tap never retains a disposed screen context.
    _onForegroundMessage = onForegroundMessage;
    _onNotificationTap = onNotificationTap;
    if (_isInitialized) return true;

    try {
      // Request permission
      final settings = await _requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('[FCM] Permission denied or not determined');
        return false;
      }

      // Handle foreground messages
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // Handle notification tap (app was in background)
      _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageOpenedApp,
      );

      // Check if app was launched from notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Listen for token refresh
      _tokenRefreshSubscription = FcmRepository.onTokenRefresh.listen((
        newToken,
      ) {
        debugPrint(
          '[FCM] Token refreshed: ${newToken.length > 20 ? '${newToken.substring(0, 20)}...' : newToken}',
        );
        _onTokenRefresh(newToken);
      });

      _isInitialized = true;
      debugPrint('[FCM] Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[FCM] Initialization failed: $e');
      return false;
    }
  }

  Future<NotificationSettings> _requestPermission() async {
    if (Platform.isIOS) {
      return await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
    // Android 13+ automatically requests permission, but we can still call this
    return await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
  }

  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] Get token failed: $e');
      return null;
    }
  }

  Future<void> registerTokenWithBackend() async {
    final token = await getFcmToken();
    if (token == null || token.isEmpty) {
      debugPrint('[FCM] No token available');
      return;
    }

    final deviceInfo = await _getDeviceInfo();
    final result = await _fcmRepository.registerToken(
      token: token,
      deviceType: deviceInfo['deviceType'],
      deviceName: deviceInfo['deviceName'],
      appVersion: deviceInfo['appVersion'],
    );

    if (result != null) {
      debugPrint('[FCM] Token registered successfully');
    } else {
      debugPrint('[FCM] Token registration failed');
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    final safeToken = newToken.length > 20
        ? '${newToken.substring(0, 20)}...'
        : newToken;
    debugPrint('[FCM] Token refreshed: $safeToken');

    final deviceInfo = await _getDeviceInfo();
    await _fcmRepository.registerToken(
      token: newToken,
      deviceType: deviceInfo['deviceType'],
      deviceName: deviceInfo['deviceName'],
      appVersion: deviceInfo['appVersion'],
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message received: ${message.messageId}');
    _onForegroundMessage?.call(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Message opened app: ${message.messageId}');
    final deepLink = message.data['deepLink'] ?? message.data['link'];
    _onNotificationTap?.call(message, deepLink);
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    return {
      'deviceType': Platform.isAndroid ? 'Android' : 'iOS',
      'deviceName': Platform.operatingSystem,
      'appVersion': '1.0.0',
    };
  }

  Future<void> removeTokenFromBackend() async {
    final token = await getFcmToken();
    if (token == null || token.isEmpty) return;

    await _fcmRepository.removeToken(token);
    debugPrint('[FCM] Token removed from backend');
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Subscribe to topic failed: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Unsubscribe from topic failed: $e');
    }
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _backgroundSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _isInitialized = false;
    debugPrint('[FCM] Disposed');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}
