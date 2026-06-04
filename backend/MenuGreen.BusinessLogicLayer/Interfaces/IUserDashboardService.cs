using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IUserDashboardService
    {
        Task<UserDashboardSummaryResponse> GetUserSummaryAsync(Guid userId);
        Task<NutritionTrendResponse> GetNutritionTrendAsync(Guid userId, DateOnly startDate, DateOnly endDate);
        Task<WeightTrendResponse> GetWeightTrendAsync(Guid userId, DateOnly startDate, DateOnly endDate);
        Task<RecommendationDashboardSummaryResponse> GetRecommendationSummaryAsync(Guid userId, int topCount = 5);
    }
}
