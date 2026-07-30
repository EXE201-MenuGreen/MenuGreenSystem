import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/token_storage.dart';
import '../models/coach_chat_models.dart';

class CoachChatRealtimeService {
  CoachChatRealtimeService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;
  final _messageController = StreamController<CoachChatMessage>.broadcast();
  final _unreadController = StreamController<int>.broadcast();

  HubConnection? _connection;
  bool _starting = false;

  Stream<CoachChatMessage> get messages => _messageController.stream;
  Stream<int> get unreadCounts => _unreadController.stream;

  Future<void> start() async {
    if (_starting || _connection?.state == HubConnectionState.Connected) {
      return;
    }
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
      connection.on('ReceiveChatMessage', _handleMessage);
      connection.on('ReceiveChatUnreadCount', _handleUnreadCount);
      _connection = connection;
      await connection.start();
    } catch (error) {
      debugPrint('[CoachChatRealtime] start failed: $error');
      await stop();
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    connection.off('ReceiveChatMessage');
    connection.off('ReceiveChatUnreadCount');
    try {
      await connection.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _messageController.close();
    await _unreadController.close();
  }

  void _handleMessage(List<Object?>? arguments) {
    final value = arguments == null || arguments.isEmpty
        ? null
        : arguments.first;
    if (value is! Map) return;
    _messageController.add(
      CoachChatMessage.fromJson(
        value.map((key, item) => MapEntry(key.toString(), item)),
      ),
    );
  }

  void _handleUnreadCount(List<Object?>? arguments) {
    final value = arguments == null || arguments.isEmpty
        ? null
        : arguments.first;
    final count = value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '');
    if (count != null) _unreadController.add(count);
  }
}
