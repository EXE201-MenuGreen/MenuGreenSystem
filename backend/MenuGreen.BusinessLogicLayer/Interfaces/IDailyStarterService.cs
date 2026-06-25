using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IDailyStarterService
    {
        Task<DailyStarterTodayResponse> GetTodayStarterAsync(Guid userId);
        Task<IEnumerable<FoodResponse>> GetFeaturedMealsAsync();
        Task SelectMealPlanAsync(Guid userId, DailyStarterSelectMealRequest request);
        Task<DailyStarterStartLogResponse> StartLogFlowAsync(Guid userId);
        Task<DailyStarterPersonalizationResponse> GetPersonalizationAsync(Guid userId);
        Task<DailyStarterPersonalizationResponse> UpdatePersonalizationAsync(Guid userId, DailyStarterPersonalizationUpdateRequest request);
        Task<IEnumerable<RecommendationItemResponse>> GetRecommendationsAsync(Guid userId, RecommendationRequest request);
        Task<UserAiProfileResponse> SavePreferenceAsync(Guid userId, UpdateUserAiProfileRequest request);
    }
}
