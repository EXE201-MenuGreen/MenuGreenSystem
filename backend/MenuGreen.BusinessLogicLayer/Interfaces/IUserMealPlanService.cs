using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IUserMealPlanService
    {
        Task<MealPlanResponse?> GetByDateAsync(Guid userId, DateOnly date);
        Task<MealPlanResponse> CreateOrUpdateDailyAsync(Guid userId, UserMealPlanUpsertRequest request);
        Task<MealPlanResponse> CreateFromDailyMenuAsync(Guid userId, CreateMealPlanFromDailyMenuRequest request);
        Task DeleteAsync(Guid userId, Guid mealPlanId);
        Task<CompleteMealPlanItemResponse> CompleteItemAsync(Guid userId, Guid itemId, CompleteMealPlanItemRequest request);
        Task<MealPlanAdherenceResponse> GetAdherenceAsync(Guid userId, DateOnly date);
    }
}
