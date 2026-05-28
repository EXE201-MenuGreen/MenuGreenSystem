using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IRecommendationService
    {
        Task<IEnumerable<RecommendationItemResponse>> RecommendByCaloriesAsync(RecommendationRequest request);
        Task<IEnumerable<RecommendationItemResponse>> RecommendByEcoAsync(RecommendationRequest request);
        Task<IEnumerable<RecommendationItemResponse>> RecommendLunchAsync(RecommendationRequest request);
        Task<MealPlanResponse> BuildDailyMenuAsync(RecommendationRequest request);
        Task<SmartScheduleResponse> BuildSmartScheduleAsync(SmartScheduleRequest request);
    }
}
