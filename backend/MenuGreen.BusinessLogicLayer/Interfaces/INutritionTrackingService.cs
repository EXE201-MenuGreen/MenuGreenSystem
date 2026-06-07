using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INutritionTrackingService
    {
        // Meal Logs
        Task<MealLogResponse> CreateMealLogAsync(Guid userId, MealLogUpsertRequest request);
        Task<MealLogResponse> GetMealLogAsync(Guid userId, Guid mealLogId);
        Task<MealLogResponse> UpdateMealLogAsync(Guid userId, Guid mealLogId, MealLogUpsertRequest request);
        Task DeleteMealLogAsync(Guid userId, Guid mealLogId);
        Task<MealLogListResponse> GetMealLogsAsync(Guid userId, int page = 1, int pageSize = 20);
        Task<MealLogResponse> GetMealLogByIdAsync(Guid userId, Guid mealLogId);
        Task<MealLogListResponse> GetMealLogsByRangeAsync(Guid userId, DateOnly startDate, DateOnly endDate);
        
        // Daily & Dashboard
        Task<MealDaySummaryResponse> GetDailySummaryAsync(Guid userId, DateOnly date);
        Task<NutritionDashboardResponse> GetDashboardAsync(Guid userId, string range, DateOnly? startDate, DateOnly? endDate);
        
        // Summary & Trends
        Task<NutritionSummaryResponse> GetNutritionSummaryAsync(Guid userId, string period = "day", DateOnly? date = null);
        Task<NutritionTrendResponse> GetNutritionTrendsAsync(Guid userId, DateOnly startDate, DateOnly endDate);
        
        // Weight Logs
        Task<WeightLogResponse> CreateWeightLogAsync(Guid userId, WeightLogUpsertRequest request);
        Task<WeightLogResponse> UpdateWeightLogAsync(Guid userId, Guid weightLogId, WeightLogUpsertRequest request);
        Task DeleteWeightLogAsync(Guid userId, Guid weightLogId);
        Task<WeightLogListResponse> GetWeightLogsAsync(Guid userId, int page = 1, int pageSize = 20);
        Task<WeightLogResponse> GetWeightLogByIdAsync(Guid userId, Guid weightLogId);
        Task<WeightTrendResponse> GetWeightTrendAsync(Guid userId, DateOnly startDate, DateOnly endDate);
    }
}
