using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SafeRecommendationGenerateRequest
    {
        public string? MealType { get; set; }
        public int? TargetCalories { get; set; }
        public int MaxResults { get; set; } = 5;
    }
}
