using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateHealthProfileRequest
    {
        [Required]
        public decimal HeightCm { get; set; }

        [Required]
        public decimal WeightKg { get; set; }

        public decimal? BodyFatPercent { get; set; }

        [Range(30.0, 300.0)]
        public decimal? TargetWeightKg { get; set; }

        [Required]
        public string ActivityLevel { get; set; } = string.Empty;

        [Required]
        public string Goal { get; set; } = string.Empty;

        /// <summary>Optional override from onboarding calorie slider (800–6000).</summary>
        [Range(800, 6000)]
        public int? TargetCalories { get; set; }
    }
}
