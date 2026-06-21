using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class UserAiProfileResponse
    {
        public Guid UserId { get; set; }
        public string? Preferences { get; set; }
        public string? DislikedFoods { get; set; }
        public string? EatingPattern { get; set; }
        public bool AllergiesAcknowledged { get; set; }
        public string? VietnamRegion { get; set; }
        public string? MealContext { get; set; }
        public int? BudgetPerMealVnd { get; set; }
        public string? PreferredPortionUnits { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
