import 'package:flutter/foundation.dart';

import '../models/vietnam_local_models.dart';
import '../repositories/vietnam_local_repositories.dart';

/// Planned vs Actual provider — `2.17 Planned vs Actual Insights`.
class PlannedVsActualProvider extends ChangeNotifier {
  PlannedVsActualProvider({PlannedVsActualRepository? repository})
      : _repo = repository ?? PlannedVsActualRepository();

  final PlannedVsActualRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;

  PlannedVsActualSummary? _summary;
  AdherenceScore? _adherence;
  DriftAnalysis? _drift;
  PlannedVsActualRecommendations? _recommendations;
  Map<String, dynamic>? _lastRecalibration;

  DateTime _from = _daysAgo(6);
  DateTime _to = DateTime.now();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PlannedVsActualSummary? get summary => _summary;
  AdherenceScore? get adherence => _adherence;
  DriftAnalysis? get drift => _drift;
  PlannedVsActualRecommendations? get recommendations => _recommendations;
  Map<String, dynamic>? get lastRecalibration => _lastRecalibration;
  DateTime get from => _from;
  DateTime get to => _to;

  void setRange(DateTime from, DateTime to) {
    if (from.isAfter(to)) {
      final tmp = from;
      from = to;
      to = tmp;
    }
    _from = from;
    _to = to;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final summary = await _repo.getSummary(from: _from, to: _to);
    if (summary.success) _summary = summary.data;

    final adherence = await _repo.getAdherenceScore(from: _from, to: _to);
    if (adherence.success) _adherence = adherence.data;

    final drift = await _repo.getDriftAnalysis(from: _from, to: _to);
    if (drift.success) _drift = drift.data;

    final recs = await _repo.getRecommendations();
    if (recs.success) _recommendations = recs.data;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> recalibrate() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repo.recalibrate();
    _isLoading = false;
    if (!result.success) {
      _errorMessage = result.translatedMessage;
      notifyListeners();
      return false;
    }
    _lastRecalibration = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : null;
    notifyListeners();
    return true;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<ApiResult<dynamic>> getMonthlyReport({
    int? month,
    int? year,
    String format = 'json',
  }) async {
    return _repo.getMonthlyReport(month: month, year: year, format: format);
  }

  static DateTime _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));
}
