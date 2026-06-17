using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecommendationGenerateRequest
    {
        public string? MealType { get; set; }
        public int? TargetCalories { get; set; }
        public bool ExcludeUserAllergies { get; set; } = true;
        public int MaxResults { get; set; } = 5;
    }
}
