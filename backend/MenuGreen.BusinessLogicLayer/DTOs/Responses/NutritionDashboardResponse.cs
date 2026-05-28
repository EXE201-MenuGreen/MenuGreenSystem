using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionDashboardResponse
    {
        public string Range { get; set; } = string.Empty;
        public List<MealDaySummaryResponse> Days { get; set; } = new();
        public List<WeightLogResponse> WeightLogs { get; set; } = new();
    }
}
