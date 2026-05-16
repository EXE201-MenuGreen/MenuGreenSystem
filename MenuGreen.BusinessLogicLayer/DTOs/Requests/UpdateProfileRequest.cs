using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateProfileRequest
    {
        public string? FullName { get; set; }
        public DateOnly? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        
        [Range(50, 300, ErrorMessage = "Chiều cao phải từ 50cm đến 300cm.")]
        public decimal? HeightCm { get; set; }
        
        [Range(20, 500, ErrorMessage = "Cân nặng phải từ 20kg đến 500kg.")]
        public decimal? WeightKg { get; set; }
        
        [Range(0, 100)]
        public decimal? BodyFatPercent { get; set; }
        
        public string? ActivityLevel { get; set; } // "Sedentary", "Light", "Moderate", "Active", "VeryActive"
        
        public string? Goal { get; set; } // "LoseWeight", "Maintain", "GainWeight", "BuildMuscle"
        
        public string? PreferredCuisine { get; set; }
    }
}
