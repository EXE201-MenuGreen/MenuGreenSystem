using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateProfileRequest
    {
        public string? FullName { get; set; }
        public DateOnly? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        
        [Range(50, 300, ErrorMessage = "Height must be between 50cm and 300cm.")]
        public decimal? HeightCm { get; set; }
        
        [Range(20, 500, ErrorMessage = "Weight must be between 20kg and 500kg.")]
        public decimal? WeightKg { get; set; }
        
        [Range(0, 100)]
        public decimal? BodyFatPercent { get; set; }
        
        public string? ActivityLevel { get; set; } // "Sedentary", "Light", "Moderate", "Active", "VeryActive"
        
        public string? Goal { get; set; } // "LoseWeight", "Maintain", "GainWeight", "BuildMuscle"
        
        public string? PreferredCuisine { get; set; }
    }
}
