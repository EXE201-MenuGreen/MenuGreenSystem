using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ProfileResponse
    {
        public Guid Id { get; set; }
        public string? FullName { get; set; }
        public string? AvatarUrl { get; set; }
        public string Role { get; set; } = string.Empty;
        public DateOnly? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public string ActivityLevel { get; set; } = string.Empty;
        public string? Goal { get; set; }
        public decimal? Bmi { get; set; }
        public int? TdeeKcal { get; set; }
        public int? BmrKcal { get; set; }
        public int? TargetCalories { get; set; }
        public int? TargetProteinG { get; set; }
        public int? TargetCarbsG { get; set; }
        public int? TargetFatG { get; set; }
        public string? PreferredCuisine { get; set; }
    }
}
