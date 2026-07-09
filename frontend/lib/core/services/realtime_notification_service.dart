import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../features/notifications/models/notification_models.dart';
import '../network/api_endpoints.dart';
import '../network/token_storage.dart';

class RealtimeNotificationService {
  RealtimeNotificationService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;
  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  HubConnection? _connection;
  bool _starting = false;

  Stream<AppNotification> get notifications => _notificationController.stream;
  Stream<int> get unreadCounts => _unreadCountController.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> start() async {
    if (_starting || isConnected) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    _starting = true;
    try {
      await stop();
      final connection = HubConnectionBuilder()
          .withUrl(
            ApiEndpoints.notificationHub,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  await _tokenStorage.getAccessToken() ?? '',
            ),
          )
          .withAutomaticReconnect()
          .build();

      connection.on('ReceiveNotification', _handleNotification);
      connection.on('ReceiveUnreadCount', _handleUnreadCount);
      connection.onclose(({error}) {
        if (error != null) {
          debugPrint('[RealtimeNotification] closed: $error');
        }
      });

      _connection = connection;
      await connection.start();
      debugPrint('[RealtimeNotification] connected');
    } catch (error) {
      debugPrint('[RealtimeNotification] start failed: $error');
      await stop();
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    try {
      connection.off('ReceiveNotification');
      connection.off('ReceiveUnreadCount');
      await connection.stop();
    } catch (error) {
      debugPrint('[RealtimeNotification] stop failed: $error');
    }
  }

  Future<void> dispose() async {
    await stop();
    await _notificationController.close();
    await _unreadCountController.close();
  }

  void _handleNotification(List<Object?>? arguments) {
    final payload = _firstArgument(arguments);
    final json = _asJsonMap(payload);
    if (json == null) return;
    _notificationController.add(AppNotification.fromJson(json));
  }

  void _handleUnreadCount(List<Object?>? arguments) {
    final value = _firstArgument(arguments);
    final count = switch (value) {
      int n => n,
      num n => n.round(),
      String s => int.tryParse(s),
      _ => null,
    };
    if (count != null) _unreadCountController.add(count);
  }

  Object? _firstArgument(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return null;
    return arguments.first;
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }
}
