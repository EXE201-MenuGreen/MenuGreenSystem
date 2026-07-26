using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class DashboardService : IDashboardService
    {
        private readonly IUserMetricsService _userMetricsService;
        private readonly IRevenueMetricsService _revenueMetricsService;
        private readonly IFoodRankingService _foodRankingService;

        public DashboardService(
            IUserMetricsService userMetricsService,
            IRevenueMetricsService revenueMetricsService,
            IFoodRankingService foodRankingService)
        {
            _userMetricsService = userMetricsService;
            _revenueMetricsService = revenueMetricsService;
            _foodRankingService = foodRankingService;
        }

        public async Task<DashboardMetricsResponse> GetMetricsAsync(int topCount = 10)
        {
            var users = await _userMetricsService.GetSummaryAsync();
            var revenue = await _revenueMetricsService.GetSummaryAsync();
            var topFoods = await _foodRankingService.GetTopFoodsAsync(topCount);

            return new DashboardMetricsResponse
            {
                TotalUsers = users.TotalUsers,
                ActiveUsers = users.ActiveUsers,
                TotalRevenueVnd = revenue.TotalRevenueVnd,
                TopFoods = topFoods,
                GeneratedAt = System.DateTime.UtcNow
            };
        }
    }
}