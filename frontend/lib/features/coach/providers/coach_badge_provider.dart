import 'package:flutter/foundation.dart';

class CoachBadgeProvider extends ChangeNotifier {
  int _pendingCount = 0;
  int _unreadNotifCount = 0;
  int _pendingMealPlanCount = 0;
  int _pendingReportCount = 0;

  int get pendingCount => _pendingCount;
  int get unreadNotifCount => _unreadNotifCount;
  int get pendingMealPlanCount => _pendingMealPlanCount;
  int get pendingReportCount => _pendingReportCount;

  void setPendingCount(int count) {
    if (_pendingCount != count) {
      _pendingCount = count;
      notifyListeners();
    }
  }

  void setUnreadNotifCount(int count) {
    if (_unreadNotifCount != count) {
      _unreadNotifCount = count;
      notifyListeners();
    }
  }

  void setPendingMealPlanCount(int count) {
    if (_pendingMealPlanCount != count) {
      _pendingMealPlanCount = count;
      notifyListeners();
    }
  }

  void setPendingReportCount(int count) {
    if (_pendingReportCount != count) {
      _pendingReportCount = count;
      notifyListeners();
    }
  }

  void decrementUnread() {
    if (_unreadNotifCount > 0) {
      _unreadNotifCount--;
      notifyListeners();
    }
  }

  /// Reset all counts (e.g. on logout).
  void reset() {
    _pendingCount = 0;
    _unreadNotifCount = 0;
    _pendingMealPlanCount = 0;
    _pendingReportCount = 0;
    notifyListeners();
  }
}
