using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INutritionAssistantService
    {
        Task<NutritionAssistantChatResponse> SendMessageAsync(string userId, NutritionAssistantChatRequest request);
        Task StreamMessageAsync(string userId, NutritionAssistantChatRequest request, Stream output, CancellationToken cancellationToken = default);
        Task<IReadOnlyList<NutritionAssistantConversationSummaryResponse>> GetConversationsAsync(string userId, int take = 20);
        Task<NutritionAssistantConversationDetailResponse> GetConversationAsync(string userId, Guid conversationId);
        Task<NutritionAssistantAdminOverviewResponse> GetAdminOverviewAsync(int recentTake = 10);
        Task<NutritionAssistantBridgeHealthResponse> GetBridgeHealthAsync();
        Task<JsonElement> GetWorkerDebugDbAsync(string? userId = null);
        Task<JsonElement> GetWorkerDebugPostgresAsync(string? userId = null);
        Task<JsonElement> GetWorkerContextAsync(string userId, string? date = null);
        Task<NutritionAssistantFeedbackResponse> CreateFeedbackAsync(string userId, NutritionAssistantFeedbackRequest request);
        Task<NutritionAssistantMealPlan7dResponse> GenerateMealPlan7dAsync(string userId, NutritionAssistantMealPlan7dRequest request);
        Task<JsonElement> GenerateWorkerRecommendationAsync(string userId, string mode, AiWorkerRecommendationRequest request);
        Task<JsonElement> ExecuteWorkerActionAsync(string userId, AiWorkerActionExecuteRequest request);
        Task<AiWorkerCrawlerNormalizeResponse> NormalizeCrawlerDataAsync(AiWorkerCrawlerNormalizeRequest request);
        Task<AiWorkerCrawlerIngestResponse> IngestCrawlerDataAsync(AiWorkerCrawlerIngestRequest request);
        Task<AiWorkerCreateTrainingSampleResponse> CreateTrainingSampleAsync(AiWorkerCreateTrainingSampleRequest request);
        Task<AiWorkerCreateTrainingSampleResponse> CreateTrainingSampleFromFeedbackAsync(string feedbackId, AiWorkerCreateSampleFromFeedbackRequest request);
        Task<AiWorkerTrainingSampleListResponse> ListTrainingSamplesAsync(string? status = null, int limit = 50);
        Task<AiWorkerTrainingSampleResponse> ReviewTrainingSampleAsync(string sampleId, AiWorkerReviewTrainingSampleRequest request);
        Task<JsonElement> RunNightlyCurationAsync(int limit = 200);
    }
}
