using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IPlannedVsActualService
    {
        Task<PlannedVsActualSummaryResponse> GetSummaryAsync(Guid userId, DateOnly from, DateOnly to);
        Task<AdherenceScoreResponse> GetAdherenceScoreAsync(Guid userId, DateOnly from, DateOnly to);
        Task<DriftAnalysisResponse> GetDriftAnalysisAsync(Guid userId, DateOnly from, DateOnly to);
        Task<RecommendationResponse> GetRecommendationsAsync(Guid userId);
        Task<RecalibrationResponse> RecalibrateNutritionAsync(Guid userId);
        Task<string> GenerateMonthlyReportHtmlAsync(Guid userId, int month, int year);
    }
}
