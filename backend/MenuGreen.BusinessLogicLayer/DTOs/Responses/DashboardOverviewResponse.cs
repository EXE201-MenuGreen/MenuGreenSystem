using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class DashboardOverviewResponse
    {
        public UserDashboardMetricsResponse Users { get; set; } = new();
        public RevenueDashboardMetricsResponse Revenue { get; set; } = new();
        public List<DashboardFoodRankingItemResponse> TopFoods { get; set; } = new();
    }
}
