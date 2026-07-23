using System;
using System.Collections.Generic;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    /// <summary>
    /// Full Coach-side view of a single weekly report. Mirrors
    /// <c>PtReviewRequestDetailResponse</c> for the shared-token flow but is
    /// scoped to a logged-in Coach (no token) and rejects access unless the
    /// report's owner is connected with the requesting Coach.
    /// </summary>
    public class CoachReportDetailResponse
    {
        public Guid ReportId { get; set; }
        public Guid ClientId { get; set; }
        public string StudentName { get; set; } = string.Empty;
        public DateOnly WeekStartDate { get; set; }
        public DateOnly WeekEndDate { get; set; }
        public DateTime ExpiresAt { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public string PtComment { get; set; } = string.Empty;
        public int? SuggestedCalorieTarget { get; set; }
        public int? SuggestedProteinTarget { get; set; }
        public List<PtSuggestedChangeDto> SuggestedChanges { get; set; } = new();
        public object? ReportData { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public DateTime? ActionedAt { get; set; }
        public string RequestType { get; set; } = "WeeklyReport";
        public decimal? CheckInWeight { get; set; }
        public decimal? CheckInBodyFat { get; set; }
        public int? TrainingDaysCount { get; set; }
        public string? BodyFeeling { get; set; }
        public string? StudentNote { get; set; }
    }
}
