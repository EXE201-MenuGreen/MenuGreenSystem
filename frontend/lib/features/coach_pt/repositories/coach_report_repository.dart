import '../../advanced/repositories/advanced_repository.dart';
import '../models/coach_report_models.dart';

/// Thin wrapper around [AdvancedRepository] for Coach-side weekly reports.
/// Methods return parsed [CoachWeeklyReport] / [CoachWeeklyReportDetail]
/// models instead of raw Maps so the UI can bind directly.
class CoachReportRepository {
  CoachReportRepository({AdvancedRepository? advanced})
      : _advanced = advanced ?? AdvancedRepository();

  final AdvancedRepository _advanced;

  /// List weekly reports across all connected Gymers (or scoped to a single
  /// Gymer when [clientId] is provided).
  /// `weekStart` (a DateTime will be normalized to yyyy-MM-dd) and `month`
  /// ('YYYY-MM') are exclusive on the wire — pass at most one.
  Future<List<CoachWeeklyReport>> listReports({
    DateTime? weekStart,
    String? month,
    CoachReportStatus? status,
    String? clientId,
  }) async {
    final raw = await _advanced.coachWeeklyReports(
      weekStart: weekStart,
      month: month,
      status: status?.apiValue,
      clientId: clientId,
    );
    return raw.map(CoachWeeklyReport.fromJson).toList();
  }

  /// Detail of a single report, including the full ReportData payload.
  Future<CoachWeeklyReportDetail> getReportDetail(String reportId) async {
    final raw = await _advanced.coachReportDetail(reportId);
    final summary = CoachWeeklyReport.fromJson(raw);
    return CoachWeeklyReportDetail.fromJson(summary, raw);
  }

  /// Coach submits review (may include inline meal-plan adjustments) and the
  /// backend will simultaneously apply the inline edits and notify the Gymer.
  Future<void> submitReview(
    String reportId,
    CoachReviewSubmission submission,
  ) =>
      _advanced.submitCoachReview(reportId, submission.toJson());
}
