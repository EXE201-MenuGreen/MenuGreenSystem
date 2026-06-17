using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IAiAssistantService
    {
        // A. Conversation lifecycle
        Task<AiConversationResponse> CreateConversationAsync(Guid userId, CreateConversationRequest request);
        Task<IEnumerable<AiConversationResponse>> GetConversationsAsync(Guid userId);
        Task<AiConversationResponse> GetConversationByIdAsync(Guid userId, Guid conversationId);
        Task DeleteConversationAsync(Guid userId, Guid conversationId);
        Task<AiConversationResponse> UpdateConversationTitleAsync(Guid userId, Guid conversationId, string newTitle);

        // B. Message workflow
        Task<AiMessageResponse> SendMessageAsync(Guid userId, Guid conversationId, SendMessageRequest request);
        Task<IEnumerable<AiMessageResponse>> GetMessagesAsync(Guid userId, Guid conversationId);
        Task<AiMessageResponse> RegenerateMessageAsync(Guid userId, Guid conversationId, Guid messageId);
        Task FeedbackMessageAsync(Guid userId, Guid conversationId, Guid messageId, MessageFeedbackRequest request);

        // C. Context & profile
        Task<AiAssistantContextResponse> GetContextAsync(Guid userId);
        Task<UserAiProfileResponse> GetProfileAsync(Guid userId);
        Task<UserAiProfileResponse> UpdateProfileAsync(Guid userId, UpdateAiProfileRequest request);

        // D. Action suggestions
        Task<IEnumerable<string>> GetSuggestionsAsync(Guid userId);
        Task<object> GenerateMealPlanFromAiAsync(Guid userId, string prompt);
        Task<object> SuggestFoodReplacementAsync(Guid userId, Guid foodId, string reason);

        // E. History/analytics
        Task<object> GetInsightsAsync(Guid userId);
        Task<string> SummarizeConversationAsync(Guid userId, Guid conversationId);
        Task<object> GetUsageMetricsAsync(Guid userId);
    }
}
