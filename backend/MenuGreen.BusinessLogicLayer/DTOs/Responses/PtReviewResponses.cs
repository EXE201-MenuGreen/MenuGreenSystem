using System;
using System.Collections.Generic;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CreatePtReviewReportResponse
    {
        public Guid ReportId { get; set; }
        public string ShareLink { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public DateOnly WeekStartDate { get; set; }
        public string RequestType { get; set; } = "WeeklyReport";
        public string Status { get; set; } = "Pending";
        public DateTime CreatedAt { get; set; }
    }

    public class PtReviewRequestDetailResponse
    {
        public Guid ReportId { get; set; }
        public string StudentName { get; set; } = string.Empty;
        public DateOnly WeekStartDate { get; set; }
        public DateTime ExpiresAt { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public string PtComment { get; set; } = string.Empty;
        public int? SuggestedCalorieTarget { get; set; }
        public int? SuggestedProteinTarget { get; set; }
        public int? ConfiguredCalorieTarget { get; set; }
        public int? ConfiguredMinCalories { get; set; }
        public int? ConfiguredMaxCalories { get; set; }
        public List<PtSuggestedChangeDto> SuggestedChanges { get; set; } = new();
        public object? ReportData { get; set; } // Parsed from ReportDataJson
        public DateTime? ReviewedAt { get; set; }
        public DateTime? ActionedAt { get; set; }
        public string ReviewToken { get; set; } = string.Empty;
        public string RequestType { get; set; } = "WeeklyReport";
        public string CreatedByRole { get; set; } = "Gymer";
        public decimal? CheckInWeight { get; set; }
        public decimal? CheckInBodyFat { get; set; }
        public int? TrainingDaysCount { get; set; }
        public string? BodyFeeling { get; set; }
        public string? StudentNote { get; set; }
    }
}
