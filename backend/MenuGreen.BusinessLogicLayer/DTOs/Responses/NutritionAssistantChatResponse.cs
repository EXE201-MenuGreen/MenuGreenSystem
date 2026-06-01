using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionAssistantChatResponse
    {
        public Guid ConversationId { get; set; }
        public Guid UserMessageId { get; set; }
        public Guid AssistantMessageId { get; set; }
        public string AssistantMessage { get; set; } = string.Empty;
        public DateTimeOffset CreatedAt { get; set; }
        public IReadOnlyList<string> SuggestedQuestions { get; set; } = Array.Empty<string>();
        public string? SafetyNotice { get; set; }
        public string? Intent { get; set; }
        public string? Source { get; set; }
        public string? RequestId { get; set; }
        public string? ThreadId { get; set; }
        public decimal? IntentConfidence { get; set; }
        public string? SubscriptionTier { get; set; }
    }
}
