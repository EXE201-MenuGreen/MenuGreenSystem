import 'package:flutter/foundation.dart';

import '../repositories/vietnam_local_repositories.dart';

/// Food Capture provider — `2.14 Real-world Food Data Capture`.
class FoodCaptureProvider extends ChangeNotifier {
  FoodCaptureProvider({FoodCaptureRepository? repository})
      : _repo = repository ?? FoodCaptureRepository();

  final FoodCaptureRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<ApiResult<dynamic>> fallbackEstimate(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.fallbackEstimate(payload);
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
    }
    notifyListeners();
    return result;
  }

  Future<ApiResult<dynamic>> saveAsQuickAdd(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.saveAsQuickAdd(payload);
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
    }
    notifyListeners();
    return result;
  }

  Future<ApiResult<dynamic>> quickTemplate(Map<String, dynamic> payload) {
    return _repo.quickTemplate(payload);
  }

  Future<ApiResult<dynamic>> templateFromPlan(DateTime date) {
    return _repo.templateFromPlan(date);
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
