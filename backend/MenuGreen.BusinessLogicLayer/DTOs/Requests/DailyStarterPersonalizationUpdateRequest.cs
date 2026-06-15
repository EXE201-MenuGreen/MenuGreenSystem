using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class DailyStarterPersonalizationUpdateRequest
    {
        public decimal? HeightCm { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? TargetCalories { get; set; }
        public string? DietaryPreference { get; set; }
        public List<AllergenProfileItem>? Allergens { get; set; }
    }
}
