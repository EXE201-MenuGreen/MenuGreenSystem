using System;
using System.Collections.Generic;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class DailyStarterPersonalizationResponse
    {
        public Guid UserId { get; set; }
        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? TargetCalories { get; set; }
        public string? DietaryPreference { get; set; }
        public List<string> AllergenKeys { get; set; } = new();
        public List<AllergenProfileItem> Allergens { get; set; } = new();
    }
}
