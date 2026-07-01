using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IRecommendationService
    {


        Task<IReadOnlyList<RecommendationHistoryResponse>> GetHistoryAsync(Guid userId);
        Task<RecommendationDetailResponse> GetByIdAsync(Guid userId, Guid recommendationId);
        Task DeleteHistoryAsync(Guid userId, Guid recommendationId);
        Task SubmitFeedbackAsync(Guid userId, RecommendationFeedbackRequest request);
        Task<RecommendationExplainResponse> ExplainAsync(Guid userId, Guid recommendationId);
        Task<RecommendationScoreResponse> GetScoresAsync(Guid userId, RecommendationScoreRequest request);
        Task<object> RetrainAsync(Guid userId, RecommendationRetrainRequest request);

        Task UpdateFeedbackAsync(Guid userId, Guid recommendationId, UpdateFeedbackRequest request);
        Task<FeedbackSummaryResponse> GetFeedbackSummaryAsync(Guid userId);
    }
}
