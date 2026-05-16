using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Profile
    {
        // For a 1-1 relationship, Id is both PK and FK referencing User.Id
        public Guid Id { get; set; }

        public string? FullName { get; set; }
        public string? AvatarUrl { get; set; }
        
        public string Role { get; set; } = "User";

        public DateOnly? DateOfBirth { get; set; }
        public string? Gender { get; set; }

        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }

        public string ActivityLevel { get; set; } = "Sedentary";
        public string? Goal { get; set; }

        public int? TdeeKcal { get; set; }
        public int? BmrKcal { get; set; }

        public int? TargetCalories { get; set; }
        public int? TargetProteinG { get; set; }
        public int? TargetCarbsG { get; set; }
        public int? TargetFatG { get; set; }

        public string? PreferredCuisine { get; set; }

        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset UpdatedAt { get; set; }

        // Navigation property
        public virtual User? User { get; set; }
    }
}
