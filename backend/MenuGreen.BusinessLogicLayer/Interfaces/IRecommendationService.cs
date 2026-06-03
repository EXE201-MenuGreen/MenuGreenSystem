using System;
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
        Task<IReadOnlyList<RecommendationHistoryResponse>> GetHistoryAsync(Guid userId);
        Task<RecommendationDetailResponse> GetByIdAsync(Guid userId, Guid recommendationId);
        Task<IReadOnlyList<RecommendationItemResponse>> PreviewAsync(Guid userId, RecommendationPreviewRequest request);
        Task SubmitFeedbackAsync(Guid userId, RecommendationFeedbackRequest request);
        Task<RecommendationExplainResponse> ExplainAsync(Guid userId, Guid recommendationId);
    }
}
