using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INutritionAssistantService
    {
        Task<NutritionAssistantChatResponse> SendMessageAsync(string userId, NutritionAssistantChatRequest request);
        Task<IReadOnlyList<NutritionAssistantConversationSummaryResponse>> GetConversationsAsync(string userId, int take = 20);
        Task<NutritionAssistantConversationDetailResponse> GetConversationAsync(string userId, Guid conversationId);
        Task<NutritionAssistantAdminOverviewResponse> GetAdminOverviewAsync(int recentTake = 10);
        Task<NutritionAssistantBridgeHealthResponse> GetBridgeHealthAsync();
    }
}
