import 'package:flutter/foundation.dart';

import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

/// Safety/Compliance provider — `2.15 Safety, Trust, Compliance`.
class SafetyProvider extends ChangeNotifier {
  SafetyProvider({SafetyRepository? repository})
      : _repo = repository ?? SafetyRepository();

  final SafetyRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;

  SafetyDisclaimer? _disclaimer;
  SafetyConsent? _consent;
  SafetyAlerts? _alerts;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SafetyDisclaimer? get disclaimer => _disclaimer;
  SafetyConsent? get consent => _consent;
  SafetyAlerts? get alerts => _alerts;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final disclaimer = await _repo.getDisclaimer();
    if (disclaimer.success) _disclaimer = disclaimer.data;

    final consent = await _repo.getConsent();
    if (consent.success) _consent = consent.data;

    final alerts = await _repo.getAlerts();
    if (alerts.success) _alerts = alerts.data;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateConsent({
    required bool analytics,
    required bool notification,
    required bool marketing,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.updateConsent(
      SafetyConsent(
        analytics: analytics,
        notification: notification,
        marketing: marketing,
      ),
    );
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _consent = result.data;
    notifyListeners();
    return true;
  }

  Future<ApiResult<dynamic>> exportData() {
    return _repo.exportData();
  }

  Future<ApiResult<String>> deleteData() {
    return _repo.deleteData();
  }

  Future<ApiResult<String>> reportIssue({
    required String category,
    required String severity,
    required String description,
    String? contactEmail,
  }) {
    return _repo.reportIssue(
      category: category,
      severity: severity,
      description: description,
      contactEmail: contactEmail,
    );
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
