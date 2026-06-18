using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class PremiumProgram
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int DurationWeeks { get; set; } // 8 or 12
        public int TargetCaloriesDaily { get; set; }
        public string GoalType { get; set; } = string.Empty; // LoseWeight, GainMuscle, HealthyEating
        public int PriceVnd { get; set; }
        public string SampleMenu { get; set; } = string.Empty; // Pipe-separated summary of foods
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public virtual ICollection<UserPremiumProgram> UserPremiumPrograms { get; set; } = new List<UserPremiumProgram>();
    }
}
