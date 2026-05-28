using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INutritionTrackingService
    {
        Task<MealLogResponse> CreateMealLogAsync(Guid userId, MealLogUpsertRequest request);
        Task<MealLogResponse> UpdateMealLogAsync(Guid userId, Guid mealLogId, MealLogUpsertRequest request);
        Task DeleteMealLogAsync(Guid userId, Guid mealLogId);
        Task<MealDaySummaryResponse> GetDailySummaryAsync(Guid userId, DateOnly date);
        Task<NutritionDashboardResponse> GetDashboardAsync(Guid userId, string range, DateOnly? startDate, DateOnly? endDate);
        Task<WeightLogResponse> CreateWeightLogAsync(Guid userId, WeightLogUpsertRequest request);
        Task<WeightLogResponse> UpdateWeightLogAsync(Guid userId, Guid weightLogId, WeightLogUpsertRequest request);
        Task DeleteWeightLogAsync(Guid userId, Guid weightLogId);
    }
}
