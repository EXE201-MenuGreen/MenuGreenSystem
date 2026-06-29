using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionAssistantConversationSummaryResponse
    {
        public Guid ConversationId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string LastMessagePreview { get; set; } = string.Empty;
        public DateTimeOffset? LastMessageAt { get; set; }
        public int MessageCount { get; set; }
    }
}
