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
  DateTime? _planDate;
  int? _planTargetCalories;
  bool _hasPlanConfiguration = false;
  int _planLoadVersion = 0;
  GymRecalibrationResult? _lastRecalibration;
  RecalibrateOutcome? _lastRecalibrateOutcome;

  bool get isLoading => _isLoading;
  bool get isRecalibrating => _isRecalibrating;
  String? get errorMessage => _errorMessage;
  GymGoalProfile? get profile => _profile;
  List<LocalRecommendationItem> get planSuggestions => _planSuggestions;
  DateTime? get planDate => _planDate;
  int? get planTargetCalories => _planTargetCalories;
  bool get hasPlanConfiguration => _hasPlanConfiguration;
  GymRecalibrationResult? get lastRecalibration => _lastRecalibration;
  RecalibrateOutcome? get lastRecalibrateOutcome => _lastRecalibrateOutcome;

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

  Future<void> loadPlan({
    required DateTime date,
    int? targetCalories,
    int? top,
  }) async {
    final loadVersion = ++_planLoadVersion;
    _planDate = date;
    _planTargetCalories = null;
    _hasPlanConfiguration = false;
    _planSuggestions = const [];
    notifyListeners();

    final result = await _repo.getPlan(
      date: date,
      targetCalories: targetCalories,
      top: top,
    );
    if (loadVersion != _planLoadVersion) return;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      _planSuggestions = const [];
      notifyListeners();
      return;
    }
    final plan = result.data;
    _planDate = plan?.date ?? date;
    _planTargetCalories = plan?.targetCalories;
    _hasPlanConfiguration = plan?.hasConfiguration ?? false;
    _planSuggestions = plan?.items ?? const [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<RecalibrateOutcome> recalibrate() async {
    _isRecalibrating = true;
    _lastRecalibrateOutcome = null;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.recalibrate();
    _isRecalibrating = false;
    if (!result.success) {
      // Backend returned a structured error code. Branch on it so the UI
      // can react specifically (e.g. open the weight log sheet instead of
      // just showing a generic error).
      switch (result.errorCode) {
        case 'RECALIBRATE_NO_WEIGHT_DATA':
          _lastRecalibrateOutcome = RecalibrateOutcome.requiresWeightLog;
        case 'RECALIBRATE_ANOMALY_WEIGHT_CHANGE':
          _lastRecalibrateOutcome = RecalibrateOutcome.requiresWeightLogReview;
        default:
          _errorMessage = result.translatedMessage;
          _lastRecalibrateOutcome = RecalibrateOutcome.failed;
      }
      notifyListeners();
      return _lastRecalibrateOutcome!;
    }
    _lastRecalibration = result.data;
    _lastRecalibrateOutcome = RecalibrateOutcome.success;
    notifyListeners();
    return _lastRecalibrateOutcome!;
  }

  /// Clear the last recalibration outcome (e.g. after the user closes the
  /// weight log sheet so the card returns to its neutral state).
  void clearRecalibrateOutcome() {
    if (_lastRecalibrateOutcome == null) return;
    _lastRecalibrateOutcome = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
