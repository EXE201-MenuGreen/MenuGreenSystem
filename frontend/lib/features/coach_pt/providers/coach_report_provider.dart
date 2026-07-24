import 'package:flutter/foundation.dart';

import '../models/coach_report_models.dart';
import '../repositories/coach_report_repository.dart';

/// State holder for the Coach-side weekly-report screens.
///
/// * [loadReports] fetches [CoachWeeklyReport]s filtered by week / month /
///   status.
/// * [loadReportDetail] caches one report's full payload in [selectedDetail]
///   so the detail screen can render ReportData (nutrition summary, daily
///   meals, weight logs) without refetching on every build.
/// * [submitReview] POSTs review + optional inline adjustments; on success
///   it drops the cached detail (the report status has changed to Reviewed
///   and the inline adjustments already pushed).
class CoachReportProvider extends ChangeNotifier {
  CoachReportProvider({CoachReportRepository? repository})
      : _repo = repository ?? CoachReportRepository();

  final CoachReportRepository _repo;

  // ─── List ───────────────────────────────────────────────────────────────
  List<CoachWeeklyReport> _reports = const [];
  bool _loading = false;
  String? _error;
  CoachReportStatus? _statusFilter;
  DateTime? _weekStart;
  String? _month; // 'YYYY-MM'
  String? _clientIdFilter; // when set, restrict to a single Gymer

  // ─── Detail ─────────────────────────────────────────────────────────────
  CoachWeeklyReportDetail? _selectedDetail;
  bool _loadingDetail = false;
  String? _detailError;

  // ─── Getters ────────────────────────────────────────────────────────────
  List<CoachWeeklyReport> get reports => _reports;
  bool get isLoading => _loading;
  String? get error => _error;
  CoachReportStatus? get statusFilter => _statusFilter;
  DateTime? get weekStart => _weekStart;
  String? get month => _month;
  String? get clientIdFilter => _clientIdFilter;

  CoachWeeklyReportDetail? get selectedDetail => _selectedDetail;
  bool get isLoadingDetail => _loadingDetail;
  String? get detailError => _detailError;

  int get pendingCount =>
      _reports.where((r) => r.status == CoachReportStatus.pending).length;

  /// Load / reload with the given filters. Pass null to clear a filter.
  Future<void> loadReports({
    DateTime? weekStart,
    String? month,
    CoachReportStatus? status,
    String? clientId,
    bool resetFilters = true,
  }) async {
    _weekStart = weekStart;
    _month = month;
    _statusFilter = status;
    if (resetFilters || clientId != null) {
      _clientIdFilter = clientId;
    }
    await _refreshList();
  }

  /// Clear the single-client filter without touching other filters.
  Future<void> clearClientFilter() async {
    _clientIdFilter = null;
    await _refreshList();
  }

  Future<void> _refreshList() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _repo.listReports(
        weekStart: _weekStart,
        month: _month,
        status: _statusFilter,
        clientId: _clientIdFilter,
      );
    } catch (e) {
      _error = e.toString();
      _reports = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _refreshList();

  Future<void> loadReportDetail(String reportId) async {
    _loadingDetail = true;
    _detailError = null;
    notifyListeners();
    try {
      _selectedDetail = await _repo.getReportDetail(reportId);
    } catch (e) {
      _detailError = e.toString();
      _selectedDetail = null;
    } finally {
      _loadingDetail = false;
      notifyListeners();
    }
  }

  /// Submit a Coach review. On success drops cached detail so the next open
  /// re-fetches fresh status.
  Future<bool> submitReview(
    String reportId,
    CoachReviewSubmission submission,
  ) async {
    try {
      await _repo.submitReview(reportId, submission);
      _selectedDetail = null;
      notifyListeners();
      await _refreshList();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearSelection() {
    _selectedDetail = null;
    _detailError = null;
    notifyListeners();
  }
}
