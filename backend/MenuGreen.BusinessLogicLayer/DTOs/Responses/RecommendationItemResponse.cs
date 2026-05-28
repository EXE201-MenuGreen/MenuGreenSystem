using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationItemResponse
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
        public int EstimatedPriceVnd { get; set; }
        public int CookingTimeMin { get; set; }
        public decimal Score { get; set; }
    }
}
