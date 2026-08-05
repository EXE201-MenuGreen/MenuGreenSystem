import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/coach_chat_models.dart';
import '../repositories/coach_chat_repository.dart';
import '../services/coach_chat_realtime_service.dart';

class CoachChatProvider extends ChangeNotifier {
  CoachChatProvider({
    CoachChatRepository? repository,
    CoachChatRealtimeService? realtime,
  }) : _repository = repository ?? CoachChatRepository(),
       _realtime = realtime ?? CoachChatRealtimeService() {
    _messageSubscription = _realtime.messages.listen(_onRealtimeMessage);
    _unreadSubscription = _realtime.unreadCounts.listen((count) {
      _unreadCount = count;
      if (!_disposed) notifyListeners();
    });
  }

  final CoachChatRepository _repository;
  final CoachChatRealtimeService _realtime;
  late final StreamSubscription<CoachChatMessage> _messageSubscription;
  late final StreamSubscription<int> _unreadSubscription;

  List<CoachChatPartner> _partners = const [];
  List<CoachChatMessage> _messages = const [];
  String? _activePartnerId;
  bool _loadingPartners = false;
  bool _loadingMessages = false;
  bool _sending = false;
  int _unreadCount = 0;
  String? _error;
  bool _disposed = false;

  List<CoachChatPartner> get partners => _partners;
  List<CoachChatMessage> get messages => _messages;
  bool get loadingPartners => _loadingPartners;
  bool get loadingMessages => _loadingMessages;
  bool get sending => _sending;
  int get unreadCount => _unreadCount;
  String? get error => _error;

  Future<void> loadPartners() async {
    await _realtime.start();
    _loadingPartners = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getPartners(),
        _repository.getUnreadCount(),
      ]);
      _partners = results[0] as List<CoachChatPartner>;
      _unreadCount = results[1] as int;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingPartners = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> openConversation(String partnerId) async {
    await _realtime.start();
    _activePartnerId = partnerId;
    _loadingMessages = true;
    _error = null;
    _messages = const [];
    notifyListeners();
    try {
      _messages = await _repository.getMessages(partnerId);
      await _repository.markRead(partnerId);
      await _refreshUnreadLocally(partnerId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingMessages = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> send(String content) async {
    final partnerId = _activePartnerId;
    final normalized = content.trim();
    if (partnerId == null || normalized.isEmpty || _sending) return false;
    _sending = true;
    notifyListeners();
    try {
      final message = await _repository.sendMessage(partnerId, normalized);
      if (!_messages.any((item) => item.id == message.id)) {
        _messages = [..._messages, message];
      }
      await _upsertPartnerFromMessage(message);
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  void closeConversation(String partnerId) {
    if (_activePartnerId == partnerId) _activePartnerId = null;
  }

  Future<void> _onRealtimeMessage(CoachChatMessage message) async {
    final partnerId = message.senderId;
    if (_activePartnerId == partnerId) {
      if (!_messages.any((item) => item.id == message.id)) {
        _messages = [..._messages, message];
      }
      unawaited(_repository.markRead(partnerId));
      if (_unreadCount > 0) _unreadCount--;
    } else {
      _unreadCount++;
    }
    await _upsertPartnerFromMessage(message);
    if (!_disposed) notifyListeners();
  }

  Future<void> _upsertPartnerFromMessage(CoachChatMessage message) async {
    final partnerId = message.isMine ? message.receiverId : message.senderId;
    final index = _partners.indexWhere(
      (partner) => partner.partnerId == partnerId,
    );
    if (index < 0) {
      try {
        _partners = await _repository.getPartners();
      } catch (_) {}
      return;
    }
    final current = _partners[index];
    final updated = CoachChatPartner(
      partnerId: current.partnerId,
      fullName: current.fullName,
      avatarUrl: current.avatarUrl,
      lastMessage: message.content,
      lastMessageAt: message.sentAt,
      unreadCount: _activePartnerId == partnerId
          ? 0
          : current.unreadCount + (message.isMine ? 0 : 1),
    );
    final copy = [..._partners]..removeAt(index);
    _partners = [updated, ...copy];
  }

  Future<void> _refreshUnreadLocally(String partnerId) async {
    final index = _partners.indexWhere(
      (partner) => partner.partnerId == partnerId,
    );
    if (index >= 0) {
      final current = _partners[index];
      _unreadCount = (_unreadCount - current.unreadCount).clamp(0, 1 << 31);
      final copy = [..._partners];
      copy[index] = CoachChatPartner(
        partnerId: current.partnerId,
        fullName: current.fullName,
        avatarUrl: current.avatarUrl,
        lastMessage: current.lastMessage,
        lastMessageAt: current.lastMessageAt,
        unreadCount: 0,
      );
      _partners = copy;
    } else {
      _unreadCount = await _repository.getUnreadCount();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _messageSubscription.cancel();
    _unreadSubscription.cancel();
    unawaited(_realtime.dispose());
    super.dispose();
  }
}
