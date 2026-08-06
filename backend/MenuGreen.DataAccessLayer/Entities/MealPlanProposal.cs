using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealPlanProposal
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid CoachId { get; set; }
        public Guid ReviewRequestId { get; set; }
        public string ProposalType { get; set; } = "CurrentWeekAdjustment";
        public string Status { get; set; } = "Draft";
        public DateOnly PeriodStart { get; set; }
        public DateOnly PeriodEnd { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime? SourcePlanVersion { get; set; }
        public DateTime? ReminderSentAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public DateTime? ActionedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual User? Coach { get; set; }
        public virtual PtReviewRequest? ReviewRequest { get; set; }
        public virtual ICollection<MealPlanProposalItem> Items { get; set; } =
            new List<MealPlanProposalItem>();
    }
}
