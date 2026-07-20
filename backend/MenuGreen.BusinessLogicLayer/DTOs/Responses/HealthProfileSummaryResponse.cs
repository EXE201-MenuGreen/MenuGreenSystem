using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class HealthProfileSummaryResponse
    {
        public Guid UserId { get; set; }
        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public decimal? TargetWeightKg { get; set; }
        public string? ActivityLevel { get; set; }
        public string? Goal { get; set; }
        public decimal? Bmi { get; set; }
        public int? BmrKcal { get; set; }
        public int? TdeeKcal { get; set; }
        public int? TargetCalories { get; set; }
        public int? TargetProteinG { get; set; }
        public int? TargetCarbsG { get; set; }
        public int? TargetFatG { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
