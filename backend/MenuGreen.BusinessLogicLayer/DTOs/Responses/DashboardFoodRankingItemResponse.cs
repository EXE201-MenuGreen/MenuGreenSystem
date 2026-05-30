using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class DashboardFoodRankingItemResponse
    {
        public Guid FoodId { get; set; }
        public string FoodName { get; set; } = string.Empty;
        public int UseCount { get; set; }
        public decimal CaloriesKcal { get; set; }
        public int EstimatedPriceVnd { get; set; }
    }
}
