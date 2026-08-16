import 'package:flutter/foundation.dart';

import '../../../core/i18n/api_message_translator_fixed.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';
import '../repositories/meal_plan_repository.dart';
import '../models/meal_plan_models.dart'; // Keep existing models for UserMealPlan

import 'dart:async';
import '../../../core/network/network_connectivity_service.dart';

/// State management cho Meal Plan
class MealPlanProvider extends ChangeNotifier {
  MealPlanProvider({MealPlanRepository? repository})
    : _repository = repository ?? MealPlanRepository() {
    _reconnectSub = NetworkConnectivityService.instance.onReconnected.listen((
      _,
    ) {
      refreshOnReconnected();
    });
  }

  final MealPlanRepository _repository;
  StreamSubscription<void>? _reconnectSub;

  // Disposed flag to prevent state updates after disposal
  bool _disposed = false;

  // States
  List<MealPlanListItem> _plans = [];
  MealPlanDetail? _currentPlan;
  MealPlanDayDashboard? _todayDashboard;
  MealPlanAdherence? _todayAdherence;
  MealPlanStreak? _streaks;
  MealPlanCompare? _compare;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isLoadingCompare = false;
  final Set<String> _pendingItemToggles = <String>{};
  String? _error;

  @override
  void dispose() {
    _disposed = true;
    _reconnectSub?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // Getters
  List<MealPlanListItem> get plans => _plans;
  MealPlanDetail? get currentPlan => _currentPlan;
  MealPlanDayDashboard? get todayDashboard => _todayDashboard;
  MealPlanAdherence? get todayAdherence => _todayAdherence;
  MealPlanStreak? get streaks => _streaks;
  MealPlanCompare? get compare => _compare;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingCompare => _isLoadingCompare;
  String? get error => _error;

  // Computed values
  int get todayPlannedCalories =>
      _todayDashboard?.plannedCalories ?? _todayAdherence?.plannedKcal ?? 0;
  int get todayActualCalories =>
      _todayDashboard?.actualCalories ??
      _todayAdherence?.actualKcal.toInt() ??
      0;
  int get todayTargetCalories =>
      _todayDashboard?.plannedCalories ?? _todayAdherence?.plannedKcal ?? 2000;
  double get todayProgressPercent {
    if (todayTargetCalories == 0) return 0;
    return (todayActualCalories / todayTargetCalories).clamp(0, 1.5);
  }

  int get todayCompletedMeals =>
      _todayDashboard?.completedMeals ?? _todayAdherence?.completedCount ?? 0;
  int get todayTotalMeals =>
      _todayDashboard?.totalMeals ?? _todayAdherence?.totalCount ?? 0;

  // ==================== Load Data ====================

  /// Load danh sách plans
  Future<void> loadPlans({bool? isActive, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      _safeNotify();
    }

    try {
      _plans = await _repository.getPlans(isActive: isActive);
      _error = null;
    } catch (e) {
      _setError(e);
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      _safeNotify();
    }
  }

  /// Load chi tiết một plan
  Future<void> loadPlanDetail(String id, {bool silent = false}) async {
    if (!silent) {
      _isLoadingDetail = true;
      _currentPlan = null;
      _error = null;
      _safeNotify();
    }

    try {
      _currentPlan = await _repository.getPlanDetail(id);
      _error = null;
    } catch (e) {
      _setError(e);
    } finally {
      if (!silent) {
        _isLoadingDetail = false;
      }
      _safeNotify();
    }
  }

  /// Load dashboard hôm nay
  Future<void> loadTodayDashboard() async {
    try {
      _todayDashboard = await _repository.getDashboard(DateTime.now());
      _todayAdherence = null;
      _safeNotify();
    } catch (_) {
      _todayDashboard = null;
      // Fallback to adherence
      try {
        _todayAdherence = await _repository.getAdherence(DateTime.now());
        _safeNotify();
      } catch (e) {
        _error = e.toString();
        _safeNotify();
      }
    }
  }

  /// Load streaks
  Future<void> loadStreaks() async {
    try {
      _streaks = await _repository.getStreaks();
      _safeNotify();
    } catch (_) {}
  }

  /// Load compare data
  Future<void> loadCompare({DateTime? from, DateTime? to}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    _isLoadingCompare = true;
    _compare = null;
    _error = null;
    _safeNotify();

    try {
      _compare = await _repository.getCompare(
        from ?? startOfMonth,
        to ?? endOfMonth,
      );
    } catch (e) {
      _setError(e);
    } finally {
      _isLoadingCompare = false;
      _safeNotify();
    }
  }

  /// Load all data cho home screen
  Future<void> loadAllForHome() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    await Future.wait([
      loadPlans(silent: true),
      loadTodayDashboard(),
      loadStreaks(),
    ]);

    _isLoading = false;
    _safeNotify();
  }

  /// Refreshes immediately after Lucky Wheel, Daily Starter, or Emotion
  /// features mutate today's plan through a different repository instance.
  Future<void> refreshAfterExternalMutation() async {
    _repository.invalidateCache();
    await loadAllForHome();
  }

  // ==================== CRUD Operations ====================

  /// Tạo plan mới
  Future<MealPlanDetail?> createPlan(CreatePlanRequest request) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final plan = await _repository.createPlan(request);
      await loadPlans();
      return plan;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Tạo plan rỗng (không cần items) - user tạo plan trước, thêm items sau.
  Future<MealPlanDetail?> createEmptyPlan(
    CreateEmptyPlanRequest request,
  ) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final plan = await _repository.createEmptyPlan(request);
      await loadPlans();
      return plan;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Tạo plan với items ngay từ đầu
  Future<MealPlanDetail?> createPlanWithItems(
    CreatePlanWithItemsRequest request,
  ) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final plan = await _repository.createPlanWithItems(request);
      await loadPlans();
      return plan;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Cập nhật plan
  Future<MealPlanDetail?> updatePlan(
    String id,
    CreatePlanRequest request,
  ) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final plan = await _repository.updatePlan(id, request);
      await loadPlans();
      return plan;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Xóa plan
  Future<bool> deletePlan(String id) async {
    try {
      await _repository.deletePlan(id);
      await loadPlans();
      if (_currentPlan?.id == id) {
        _currentPlan = null;
      }
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  /// Nhân bản plan
  Future<MealPlanDetail?> duplicatePlan(
    String id,
    DuplicatePlanRequest request,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final plan = await _repository.duplicatePlan(id, request);
      await loadPlans();
      return plan;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Item Operations ====================

  /// Thêm item vào plan
  Future<MealPlanItemDetail?> addItem(
    String planId,
    AddItemRequest request,
  ) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final item = await _repository.addItem(planId, request);
      await loadPlanDetail(planId);
      await Future.wait([loadTodayDashboard(), loadPlans(silent: true)]);
      return item;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Cập nhật item
  Future<MealPlanItemDetail?> updateItem(
    String planId,
    String itemId,
    AddItemRequest request,
  ) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final item = await _repository.updateItem(planId, itemId, request);
      await loadPlanDetail(planId);
      await Future.wait([loadTodayDashboard(), loadPlans(silent: true)]);
      return item;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Xóa item
  Future<bool> deleteItem(String planId, String itemId) async {
    try {
      await _repository.deleteItem(planId, itemId);
      await loadPlanDetail(planId);
      await Future.wait([loadTodayDashboard(), loadPlans(silent: true)]);
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật status item
  Future<MealPlanItemDetail?> updateItemStatus(
    String planId,
    String itemId,
    String status,
  ) async {
    try {
      final item = await _repository.updateItemStatus(planId, itemId, status);
      await loadPlanDetail(planId);
      await Future.wait([loadTodayDashboard(), loadPlans(silent: true)]);
      return item;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return null;
    }
  }

  /// Mark item là done
  Future<MealPlanItemDetail?> markItemDone(String planId, String itemId) async {
    return updateItemStatus(planId, itemId, 'done');
  }

  /// Toggle trạng thái hoàn thành của item (Đã ăn / Chưa ăn)
  Future<bool> toggleItemCompletion(
    String itemId,
    bool isCompleted, {
    String? planId,
  }) async {
    if (!_pendingItemToggles.add(itemId)) return false;

    // Optimistic UI update
    if (_todayDashboard != null) {
      final newItems = _todayDashboard!.plannedItems.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            isCompleted: isCompleted,
            status: isCompleted ? 'done' : 'planned',
          );
        }
        return item;
      }).toList();
      _todayDashboard = _todayDashboard!.copyWith(plannedItems: newItems);
      _safeNotify();
    }

    try {
      _error = null;
      await _repository.toggleItem(itemId, isCompleted);
      await _refreshAfterCompletionChange(planId: planId);
      return true;
    } catch (e) {
      _error = ApiMessageTranslator.translate(e.toString());
      await loadTodayDashboard();
      _safeNotify();
      return false;
    } finally {
      _pendingItemToggles.remove(itemId);
    }
  }

  /// Hoàn thành nhiều món rồi chỉ tải lại dashboard/lịch sử một lần.
  Future<int> completeItems(
    Iterable<MealPlanItemDetail> items, {
    String? planId,
  }) async {
    final pendingItems = items.where((item) => !item.isDone).toList();
    if (pendingItems.isEmpty) return 0;

    // Optimistic UI update for all pending items
    if (_todayDashboard != null) {
      final pendingIds = pendingItems.map((i) => i.id).toSet();
      final newItems = _todayDashboard!.plannedItems.map((item) {
        if (pendingIds.contains(item.id)) {
          return item.copyWith(isCompleted: true, status: 'done');
        }
        return item;
      }).toList();
      _todayDashboard = _todayDashboard!.copyWith(plannedItems: newItems);
      _safeNotify();
    }

    _error = null;
    var completedCount = 0;
    Object? firstError;

    for (final item in pendingItems) {
      if (!_pendingItemToggles.add(item.id)) {
        continue;
      }
      try {
        await _repository.toggleItem(item.id, true);
        completedCount++;
      } catch (error) {
        firstError ??= error;
      } finally {
        _pendingItemToggles.remove(item.id);
      }
    }

    await _refreshAfterCompletionChange(planId: planId);
    if (firstError != null) {
      _error = ApiMessageTranslator.translate(firstError.toString());
      _safeNotify();
    }
    return completedCount;
  }

  Future<void> _refreshAfterCompletionChange({String? planId}) async {
    if (planId != null) {
      await loadPlanDetail(planId, silent: true);
    }
    await Future.wait([
      loadTodayDashboard(),
      loadStreaks(),
      loadPlans(silent: true),
    ]);
  }

  /// Mark item là skipped
  Future<MealPlanItemDetail?> skipItem(String planId, String itemId) async {
    return updateItemStatus(planId, itemId, 'skipped');
  }

  /// Convert item thành meal log
  Future<ConvertToLogResult?> convertItemToLog(
    String planId,
    String itemId,
    ConvertToLogRequest request,
  ) async {
    try {
      final result = await _repository.convertItemToLog(
        planId,
        itemId,
        request,
      );
      await loadPlanDetail(planId);
      await Future.wait([
        loadTodayDashboard(),
        loadStreaks(),
        loadPlans(silent: true),
      ]);
      return result;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return null;
    }
  }

  Future<MealPlanItemDetail?> addRecommendationToTodayPlan(
    AddItemRequest request,
  ) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final today = DateTime.now();

      // Load current plans to find an active one
      _plans = await _repository.getPlans();

      MealPlanListItem? activePlan;
      if (_plans.isNotEmpty) {
        activePlan = _plans.firstWhere(
          (p) => p.isActive,
          orElse: () => _plans.first,
        );
      }

      if (activePlan != null) {
        final item = await _repository.addItem(activePlan.id, request);
        await loadPlanDetail(activePlan.id);
        await loadTodayDashboard();
        return item;
      }

      final title =
          'Kế hoạch ${MealType.fromString(request.mealType).labelVi} ${_formatDateShort(today)}';
      final plan = await _repository.createPlanWithItems(
        CreatePlanWithItemsRequest(
          title: title,
          planType: 'daily',
          startDate: DateTime(today.year, today.month, today.day),
          endDate: DateTime(today.year, today.month, today.day),
          targetCalories: request.targetCalories,
          isActive: true,
          items: [request.toCreateItemRequest()],
        ),
      );
      await loadPlans();
      await loadTodayDashboard();
      return plan.items.isNotEmpty ? plan.items.first : null;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  static String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  // ==================== Helpers ====================

  void _setError(dynamic e) {
    if (e == null) {
      _error = null;
    } else {
      _error = ApiMessageTranslator.translate(e.toString());
    }
  }

  /// Tự động tải lại dữ liệu khi máy chủ khôi phục kết nối
  Future<void> refreshOnReconnected() async {
    await loadAllForHome();
    if (_currentPlan != null) {
      await loadPlanDetail(_currentPlan!.id, silent: true);
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _plans = [];
    _currentPlan = null;
    _todayDashboard = null;
    _todayAdherence = null;
    _streaks = null;
    _compare = null;
    _isLoading = false;
    _isLoadingDetail = false;
    _isLoadingCompare = false;
    _pendingItemToggles.clear();
    _error = null;
    _safeNotify();
  }
}
