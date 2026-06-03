using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ProfileSummaryResponse
    {
        public Guid UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? FullName { get; set; }
        public string? AvatarUrl { get; set; }
        public string? Gender { get; set; }
        public DateOnly? DateOfBirth { get; set; }
        public string? PreferredCuisine { get; set; }
        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public string ActivityLevel { get; set; } = string.Empty;
        public string? Goal { get; set; }
        public decimal? Bmi { get; set; }
        public int? BmrKcal { get; set; }
        public int? TdeeKcal { get; set; }
        public int? TargetCalories { get; set; }
        public int? TargetProteinG { get; set; }
        public int? TargetCarbsG { get; set; }
        public int? TargetFatG { get; set; }
        public int AllergyCount { get; set; }
        public bool HasProfile { get; set; }
        public bool HasHealthProfile { get; set; }
        public bool HasAllergies { get; set; }
        public bool HasAiProfile { get; set; }
        public IReadOnlyList<string> OnboardingStepsCompleted { get; set; } = Array.Empty<string>();
    }
}
