/// ----------------------------------------------------------------------------
/// Coach-side weekly-report models (Phase 2 backend response shapes).
///
/// These wrap the raw [Map<String, dynamic>] payloads returned by
/// [AdvancedRepository.coachWeeklyReports] / `coachReportDetail` /
/// `submitCoachReview`.
///
/// The Coach reviews a Gymer's report (one week's summary) and submits feedback
/// with optional inline meal-plan adjustments via
/// [CoachReviewSubmission].
///
/// The full ReportData payload (nutrition summary, daily meals, weight logs,
/// adherence score, drift analysis) is provided in [CoachWeeklyReportDetail.reportData]
/// as a raw Map so callers can render it without forcing a heavy schema here.
/// ----------------------------------------------------------------------------
library;

enum CoachReportStatus {
  pending,
  reviewed,
  applied,
  rejected;

  static CoachReportStatus parse(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'reviewed':
        return CoachReportStatus.reviewed;
      case 'applied':
        return CoachReportStatus.applied;
      case 'rejected':
        return CoachReportStatus.rejected;
      default:
        return CoachReportStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case CoachReportStatus.pending:
        return 'Pending';
      case CoachReportStatus.reviewed:
        return 'Reviewed';
      case CoachReportStatus.applied:
        return 'Applied';
      case CoachReportStatus.rejected:
        return 'Rejected';
    }
  }
}

class CoachWeeklyReport {
  CoachWeeklyReport({
    required this.reportId,
    required this.studentName,
    required this.weekStartDate,
    required this.status,
    required this.createdAt,
    this.clientId,
    this.expiresAt,
    this.reviewedAt,
    this.actionedAt,
    this.suggestedCalorieTarget,
    this.suggestedProteinTarget,
    this.checkInWeight,
    this.trainingDaysCount,
    this.requestType = 'WeeklyReport',
  });

  final String reportId;

  /// Backend does NOT include this in the list view, only in detail. Keep
  /// nullable so a list-mode result renders gracefully.
  final String? clientId;
  final String studentName;
  final DateTime weekStartDate;
  final CoachReportStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? reviewedAt;
  final DateTime? actionedAt;
  final int? suggestedCalorieTarget;
  final int? suggestedProteinTarget;
  final double? checkInWeight;
  final int? trainingDaysCount;
  final String requestType;

  bool get isMidWeekCheckIn => requestType.toLowerCase() == 'midweekcheckin';

  bool get isPending => status == CoachReportStatus.pending;
  bool get isReviewed => status == CoachReportStatus.reviewed;

  factory CoachWeeklyReport.fromJson(Map<String, dynamic> j) {
    return CoachWeeklyReport(
      reportId: (j['reportId'] ?? j['ReportId']) as String,
      clientId: (j['clientId'] ?? j['userId'] ?? j['UserId'])?.toString(),
      studentName: (j['studentName'] ?? j['StudentName'] ?? '') as String,
      weekStartDate:
          _date(j['weekStartDate'] ?? j['WeekStartDate']) ?? DateTime.now(),
      status: CoachReportStatus.parse((j['status'] ?? j['Status']) as String?),
      createdAt: _dateTime(j['createdAt'] ?? j['CreatedAt']) ?? DateTime.now(),
      expiresAt: _dateTime(j['expiresAt'] ?? j['ExpiresAt']),
      reviewedAt: _dateTime(j['reviewedAt'] ?? j['ReviewedAt']),
      actionedAt: _dateTime(j['actionedAt'] ?? j['ActionedAt']),
      suggestedCalorieTarget:
          (j['suggestedCalorieTarget'] ?? j['SuggestedCalorieTarget']) as int?,
      suggestedProteinTarget:
          (j['suggestedProteinTarget'] ?? j['SuggestedProteinTarget']) as int?,
      checkInWeight: _num(j['checkInWeight'] ?? j['CheckInWeight'])?.toDouble(),
      trainingDaysCount:
          (j['trainingDaysCount'] ?? j['TrainingDaysCount']) as int?,
      requestType: (j['requestType'] ?? j['RequestType'] ?? 'WeeklyReport')
          .toString(),
    );
  }
}

class CoachWeeklyReportDetail {
  CoachWeeklyReportDetail({
    required this.summary,
    required this.ptComment,
    required this.suggestedChanges,
    required this.reportData,
    this.mealPlanProposal,
  });

  final CoachWeeklyReport summary;
  final String ptComment;

  /// Raw list of [PtSuggestedChangeDto]-shaped maps.
  final List<Map<String, dynamic>> suggestedChanges;

  /// Full report payload (nutrition summary, adherence, drift, weight logs,
  /// daily meals, etc.) — pass to a deep sub-screen as-is.
  final Map<String, dynamic>? reportData;
  final Map<String, dynamic>? mealPlanProposal;

  factory CoachWeeklyReportDetail.fromJson(
    CoachWeeklyReport summary,
    Map<String, dynamic> j,
  ) {
    final raw =
        (j['suggestedChanges'] ?? j['SuggestedChanges'] ?? const []) as List;
    return CoachWeeklyReportDetail(
      summary: summary,
      ptComment: (j['ptComment'] ?? j['PtComment'] ?? '') as String,
      suggestedChanges: raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      reportData: j['reportData'] is Map
          ? Map<String, dynamic>.from(j['reportData'] as Map)
          : null,
      mealPlanProposal: (j['mealPlanProposal'] ?? j['MealPlanProposal']) is Map
          ? Map<String, dynamic>.from(
              (j['mealPlanProposal'] ?? j['MealPlanProposal']) as Map,
            )
          : null,
    );
  }
}

/// One inline meal-plan adjustment submitted alongside a Coach review.
class MealPlanAdjustment {
  MealPlanAdjustment({
    this.planId,
    this.itemId,
    required this.action, // 'add' | 'remove' | 'replace'
    required this.mealType, // breakfast | lunch | dinner | snack
    required this.plannedDate,
    this.foodId,
    this.recipeId,
    this.targetCalories,
  });

  final String? planId;
  final String? itemId;
  final String action;
  final String mealType;
  final DateTime plannedDate;
  final String? foodId;
  final String? recipeId;
  final int? targetCalories;

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'itemId': itemId,
    'action': action.toLowerCase(),
    'mealType': mealType.toLowerCase(),
    'plannedDate':
        '${plannedDate.year.toString().padLeft(4, '0')}-'
        '${plannedDate.month.toString().padLeft(2, '0')}-'
        '${plannedDate.day.toString().padLeft(2, '0')}',
    if (foodId != null) 'foodId': foodId,
    if (recipeId != null) 'recipeId': recipeId,
    if (targetCalories != null) 'targetCalories': targetCalories,
  };
}

/// Body posted to POST /api/PtReview/coach/reports/{reportId}/review.
class CoachReviewSubmission {
  CoachReviewSubmission({
    required this.comment,
    this.suggestedCalorieTarget,
    this.suggestedProteinTarget,
    this.adjustments = const [],
  });

  final String comment;
  final int? suggestedCalorieTarget;
  final int? suggestedProteinTarget;
  final List<MealPlanAdjustment> adjustments;

  Map<String, dynamic> toJson() => {
    'comment': comment,
    if (suggestedCalorieTarget != null)
      'suggestedCalorieTarget': suggestedCalorieTarget,
    if (suggestedProteinTarget != null)
      'suggestedProteinTarget': suggestedProteinTarget,
    if (adjustments.isNotEmpty)
      'adjustMealPlanItems': adjustments.map((a) => a.toJson()).toList(),
  };
}

DateTime? _date(dynamic raw) {
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

DateTime? _dateTime(dynamic raw) {
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

num? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}
