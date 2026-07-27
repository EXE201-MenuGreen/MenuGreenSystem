using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class PtReviewRequest
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public DateOnly WeekStartDate { get; set; }
        public string ReviewToken { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Reviewed, Applied, Rejected
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Static serialized JSON representing the WeeklyReport details
        public string ReportDataJson { get; set; } = string.Empty;

        // Feedback and target recommendations submitted by PT
        public string? PtComment { get; set; }
        public int? SuggestedCalorieTarget { get; set; }
        public int? SuggestedProteinTarget { get; set; }
        public int? SuggestedFatTarget { get; set; }
        public int? SuggestedCarbsTarget { get; set; }
        
        // JSON array of proposed meal alterations
        public string? SuggestedChangesJson { get; set; }

        public DateTime? ReviewedAt { get; set; }
        public DateTime? ActionedAt { get; set; }

        // Phase 8: PersonalProgram support (PT -> Gymer direction)
        // "Gymer" = user submitted a RouteApproval/WeeklyReport via /api/PtReview/reports.
        // "Coach" = coach submitted a PersonalProgram via /api/PtReview/coach/personal-programs.
        public string CreatedByRole { get; set; } = "Gymer";

        // Set when Gymer accepts a PersonalProgram from coach.
        // Nullable to preserve existing Gymer-side RouteApproval records.
        public DateTime? AcceptedAt { get; set; }
        public Guid? AcceptedByUserId { get; set; }

        // Navigation properties
        public virtual User? User { get; set; }
    }
}
