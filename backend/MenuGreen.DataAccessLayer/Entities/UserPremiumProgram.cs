using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class UserPremiumProgram
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid ProgramId { get; set; }
        public DateOnly? StartDate { get; set; }
        public string Status { get; set; } = "PendingPayment"; // PendingPayment, Active, Completed
        public int CurrentWeek { get; set; } = 1;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual User? User { get; set; }
        public virtual PremiumProgram? PremiumProgram { get; set; }
        public virtual ICollection<UserProgramMilestone> UserProgramMilestones { get; set; } = new List<UserProgramMilestone>();
    }
}
