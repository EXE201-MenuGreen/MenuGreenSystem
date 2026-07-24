using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    /// <summary>
    /// Lightweight summary used by Coach-side weekly report list.
    /// One row per <c>PtReviewRequest</c> scoped to Gymers that are
    /// currently <c>Connected</c> with the requesting coach.
    /// </summary>
    public class CoachReportSummary
    {
        public Guid ReportId { get; set; }
        public Guid ClientId { get; set; }
        public string StudentName { get; set; } = string.Empty;
        public DateOnly WeekStartDate { get; set; }
        public DateOnly WeekEndDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public DateTime? ActionedAt { get; set; }
        public decimal? CheckInWeight { get; set; }
        public int? TrainingDaysCount { get; set; }
        public string RequestType { get; set; } = "WeeklyReport";
    }
}
