using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IRecommendationService
    {
        Task<IEnumerable<RecommendationItemResponse>> RecommendByCaloriesAsync(Guid? userId, RecommendationRequest request);
        Task<IEnumerable<RecommendationItemResponse>> RecommendByEcoAsync(Guid? userId, RecommendationRequest request);
        Task<IEnumerable<RecommendationItemResponse>> RecommendLunchAsync(Guid? userId, RecommendationRequest request);
        Task<MealPlanResponse> BuildDailyMenuAsync(Guid? userId, RecommendationRequest request);
        Task<SmartScheduleResponse> BuildSmartScheduleAsync(SmartScheduleRequest request);
        Task<IReadOnlyList<RecommendationHistoryResponse>> GetHistoryAsync(Guid userId);
        Task<RecommendationDetailResponse> GetByIdAsync(Guid userId, Guid recommendationId);
        Task<IReadOnlyList<RecommendationItemResponse>> PreviewAsync(Guid userId, RecommendationPreviewRequest request);
        Task SubmitFeedbackAsync(Guid userId, RecommendationFeedbackRequest request);
        Task<RecommendationExplainResponse> ExplainAsync(Guid userId, Guid recommendationId);
        Task<RecommendationScoreResponse> GetScoresAsync(Guid userId, RecommendationScoreRequest request);
        Task<object> RetrainAsync(Guid userId, RecommendationRetrainRequest request);
        Task<RecommendationGenerateResponse> GenerateAsync(Guid userId, RecommendationGenerateRequest request);
        Task<WeeklyPlanGenerateResponse> GenerateWeeklyPlanAsync(Guid userId, WeeklyPlanGenerateRequest request);
        Task<BudgetAwareGenerateResponse> GenerateBudgetAwareAsync(Guid userId, BudgetAwareGenerateRequest request);
        Task UpdateFeedbackAsync(Guid userId, Guid recommendationId, UpdateFeedbackRequest request);
        Task<FeedbackSummaryResponse> GetFeedbackSummaryAsync(Guid userId);
    }
}
