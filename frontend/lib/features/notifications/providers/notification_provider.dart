import 'package:flutter/foundation.dart';

import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  static const int _pageSize = 20;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = refresh || _notifications.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final results = await _repository.getNotifications(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (refresh || _currentPage == 1) {
        _notifications = results;
      } else {
        _notifications.addAll(results);
      }

      _hasMore = results.length >= _pageSize;
      _currentPage++;
    } catch (e) {
      _error = 'Không thể tải thông báo';
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final results = await _repository.getNotifications(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      _notifications.addAll(results);
      _hasMore = results.length >= _pageSize;
      _currentPage++;
    } catch (e) {
      // Silent fail for load more
    } finally {
      if (mounted) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      if (mounted) notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final notification = _notifications[index];
    if (notification.isRead) return;

    _notifications[index] = notification.copyWith(isRead: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    final success = await _repository.markAsRead(id);
    if (!success && mounted) {
      _notifications[index] = notification;
      _unreadCount++;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final previousNotifications = List<AppNotification>.from(_notifications);
    final previousCount = _unreadCount;

    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    final success = await _repository.markAllAsRead();
    if (!success && mounted) {
      _notifications = previousNotifications;
      _unreadCount = previousCount;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final notification = _notifications[index];
    _notifications.removeAt(index);
    if (!notification.isRead && _unreadCount > 0) _unreadCount--;
    notifyListeners();

    final success = await _repository.deleteNotification(id);
    if (!success && mounted) {
      _notifications.insert(index, notification);
      if (!notification.isRead) _unreadCount++;
      notifyListeners();
    }
  }

  Future<void> trackOpen(String id) async {
    await _repository.trackOpen(id);
  }

  Future<void> trackClick(String id) async {
    await _repository.trackClick(id);
  }

  void refresh() {
    loadNotifications(refresh: true);
    loadUnreadCount();
  }
}
