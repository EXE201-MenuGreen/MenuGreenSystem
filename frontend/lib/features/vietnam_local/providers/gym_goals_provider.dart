import 'package:flutter/foundation.dart';

import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

/// Gym/PT Goal provider — `2.13 Gym/PT Goal-Based Workflow`.
class GymGoalsProvider extends ChangeNotifier {
  GymGoalsProvider({GymGoalsRepository? repository})
      : _repo = repository ?? GymGoalsRepository();

  final GymGoalsRepository _repo;

  bool _isLoading = false;
  bool _isRecalibrating = false;
  String? _errorMessage;

  GymGoalProfile? _profile;
  List<LocalRecommendationItem> _planSuggestions = const [];
  GymRecalibrationResult? _lastRecalibration;

  bool get isLoading => _isLoading;
  bool get isRecalibrating => _isRecalibrating;
  String? get errorMessage => _errorMessage;
  GymGoalProfile? get profile => _profile;
  List<LocalRecommendationItem> get planSuggestions => _planSuggestions;
  GymRecalibrationResult? get lastRecalibration => _lastRecalibration;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.getMe();
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      _profile = null;
      notifyListeners();
      return;
    }
    _profile = result.data;
    notifyListeners();
  }

  Future<bool> save(GymGoalProfile profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.upsert(profile);
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _profile = profile;
    notifyListeners();
    return true;
  }

  Future<void> loadPlan({int? targetCalories, int? top}) async {
    final result = await _repo.getPlan(targetCalories: targetCalories, top: top);
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      _planSuggestions = const [];
      notifyListeners();
      return;
    }
    _planSuggestions = result.data ?? const [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> recalibrate() async {
    _isRecalibrating = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.recalibrate();
    _isRecalibrating = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _lastRecalibration = result.data;
    notifyListeners();
    return true;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
