using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanResponse
    {
        public decimal TotalCalories { get; set; }
        public decimal TargetCalories { get; set; }
        public decimal TotalProteinG { get; set; }
        public decimal TotalCarbsG { get; set; }
        public decimal TotalFatG { get; set; }
        public List<RecommendationItemResponse> Breakfast { get; set; } = new();
        public List<RecommendationItemResponse> Lunch { get; set; } = new();
        public List<RecommendationItemResponse> Dinner { get; set; } = new();
        public List<RecommendationItemResponse> Snack { get; set; } = new();
    }
}
