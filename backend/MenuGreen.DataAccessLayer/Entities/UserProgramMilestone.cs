using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class UserProgramMilestone
    {
        public Guid Id { get; set; }
        public Guid UserProgramId { get; set; }
        public int WeekNumber { get; set; }
        public bool IsUnlocked { get; set; } = false;
        public bool IsCheckedIn { get; set; } = false;
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public decimal? ChestCm { get; set; }
        public decimal? WaistCm { get; set; }
        public decimal? HipCm { get; set; }
        public int RewardPoints { get; set; }
        public string? BadgeName { get; set; }
        public DateTime? CheckInDate { get; set; }
        public DateTime? UnlockedAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public virtual UserPremiumProgram? UserPremiumProgram { get; set; }
    }
}
