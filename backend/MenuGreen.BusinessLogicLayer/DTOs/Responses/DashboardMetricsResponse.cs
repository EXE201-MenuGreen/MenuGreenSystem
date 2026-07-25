namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class DashboardMetricsResponse
    {
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int TotalRevenueVnd { get; set; }
        public List<DashboardFoodRankingItemResponse> TopFoods { get; set; } = new();
        public DateTime GeneratedAt { get; set; }
    }
}