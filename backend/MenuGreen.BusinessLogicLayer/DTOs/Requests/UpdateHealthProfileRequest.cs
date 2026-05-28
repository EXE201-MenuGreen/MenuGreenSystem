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

        [Required]
        public string ActivityLevel { get; set; } = string.Empty;

        [Required]
        public string Goal { get; set; } = string.Empty;
    }
}
