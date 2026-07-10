import 'package:flutter/foundation.dart';

import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

/// Daily Starter provider — `2.12 Beginner Quick-Start` ("Hôm nay ăn gì?").
class DailyStarterProvider extends ChangeNotifier {
  DailyStarterProvider({DailyStarterRepository? repository})
      : _repo = repository ?? DailyStarterRepository();

  final DailyStarterRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  DailyStarterToday? _today;
  List<DailyStarterFood> _featured = const [];
  DailyStarterPersonalization? _personalization;
  bool _isPersonalizationLoading = false;

  bool get isLoading => _isLoading;
  bool get isPersonalizationLoading => _isPersonalizationLoading;
  String? get errorMessage => _errorMessage;
  DailyStarterToday? get today => _today;
  List<DailyStarterFood> get featured => _featured;
  DailyStarterPersonalization? get personalization => _personalization;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final todayResult = await _repo.getToday();
    if (todayResult.success) {
      _today = todayResult.data;
    }
    final featuredResult = await _repo.getFeaturedMeals();
    if (featuredResult.success && featuredResult.data != null) {
      _featured = featuredResult.data!;
    }

    _isLoading = false;
    if (!todayResult.success && !featuredResult.success) {
      _errorMessage = todayResult.translatedMessage.isNotEmpty
          ? todayResult.translatedMessage
          : 'Không tải được dữ liệu.';
    }
    notifyListeners();
  }

  Future<bool> refreshPersonalization() async {
    _isPersonalizationLoading = true;
    notifyListeners();
    final result = await _repo.getPersonalization();
    _isPersonalizationLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _personalization = result.data;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> submitPersonalization({
    double? heightCm,
    double? weightKg,
    double? targetCalories,
    String? dietaryPreference,
  }) async {
    _isPersonalizationLoading = true;
    notifyListeners();
    final result = await _repo.updatePersonalization({
      if (heightCm != null) 'heightCm': heightCm,
      if (weightKg != null) 'weightKg': weightKg,
      if (targetCalories != null) 'targetCalories': targetCalories,
      if (dietaryPreference != null) 'dietaryPreference': dietaryPreference,
    });
    _isPersonalizationLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _personalization = result.data;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<String?> selectMeal(Map<String, dynamic> payload) async {
    final result = await _repo.selectMeal(payload);
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return result.translatedMessage;
    }
    _errorMessage = null;
    notifyListeners();
    return result.data;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
