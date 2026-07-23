using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IAnalyticsService
    {
        Task<ActivityLogResponse> CreateActivityLogAsync(Guid userId, ActivityLogCreateRequest request);
        Task<IEnumerable<ActivityLogResponse>> CreateActivityLogsAsync(Guid userId, IEnumerable<ActivityLogCreateRequest> requests);
        Task<IEnumerable<ActivityLogResponse>> GetActivityLogsAsync(Guid? userId = null, DateTimeOffset? from = null, DateTimeOffset? to = null, string? action = null);
        Task<(IEnumerable<ActivityLogResponse> Items, int TotalCount)> GetActivityLogsPaginatedAsync(Guid? userId = null, DateTimeOffset? from = null, DateTimeOffset? to = null, string? action = null, int page = 1, int pageSize = 50);
        Task<ActivityLogResponse> GetActivityLogByIdAsync(Guid id);
        Task<AnalyticsDashboardResponse> GetDashboardAsync();
        Task<AnalyticsSummaryResponse> GetSummaryAsync(DateTimeOffset from, DateTimeOffset to);
        Task<IEnumerable<object>> GetMetricsAsync(DateTimeOffset from, DateTimeOffset to);
        Task<IEnumerable<AnalyticsTopEventResponse>> GetTopEventsAsync(DateTimeOffset from, DateTimeOffset to);
        Task<IEnumerable<AnalyticsFunnelStepResponse>> GetFunnelAsync();
        Task<IEnumerable<AnalyticsFunnelStepResponse>> PreviewFunnelAsync(IEnumerable<string> steps);
        Task<IEnumerable<AnalyticsFunnelStepResponse>> GetMealOnboardingFunnelAsync();
        Task<IEnumerable<AnalyticsFunnelStepResponse>> GetSubscriptionFunnelAsync();
        Task<IEnumerable<AnalyticsCohortResponse>> GetCohortAsync();
        Task<IEnumerable<object>> GetRetentionAsync();
        Task<IEnumerable<AnalyticsCohortResponse>> GetCohortBySignupDateAsync();
        Task<IEnumerable<AnalyticsCohortResponse>> GetCohortByFirstMealLogAsync();
        Task<IEnumerable<AnalyticsCohortResponse>> GetCohortBySubscriptionAsync();
        Task<IEnumerable<AnalyticsFunnelStepResponse>> GetDropOffAsync();
        Task<IEnumerable<object>> GetChurnRiskAsync();
        Task<IEnumerable<AnalyticsInactiveUserResponse>> GetInactiveUsersAsync();
        Task<IEnumerable<object>> GetReactivationOpportunitiesAsync();
        Task<IEnumerable<ActivityLogResponse>> ExportActivityLogsAsync(DateTimeOffset? from = null, DateTimeOffset? to = null);
        Task<IEnumerable<AnalyticsFunnelStepResponse>> ExportFunnelAsync();
        Task<IEnumerable<AnalyticsCohortResponse>> ExportCohortAsync();

        // Nutrition Analytics
        Task<AnalyticsNutritionDashboardResponse> GetNutritionDashboardAsync(DateTimeOffset from, DateTimeOffset to);
        Task<AnalyticsMacroDistributionResponse> GetMacroDistributionAsync(DateTimeOffset from, DateTimeOffset to);
        Task<AnalyticsGoalAchievementResponse> GetGoalAchievementAsync(DateTimeOffset from, DateTimeOffset to);
        Task<AnalyticsTopFoodsResponse> GetTopFoodsAsync(DateTimeOffset from, DateTimeOffset to, int limit, string sortBy);
        Task<AnalyticsCalorieDistributionResponse> GetCalorieDistributionAsync(DateTimeOffset from, DateTimeOffset to);
        Task<AnalyticsMealTypeBreakdownResponse> GetMealTypeBreakdownAsync(DateTimeOffset from, DateTimeOffset to);
        Task<AnalyticsUserInsightsResponse> GetUserInsightsAsync(DateTimeOffset from, DateTimeOffset to);
    }
}
