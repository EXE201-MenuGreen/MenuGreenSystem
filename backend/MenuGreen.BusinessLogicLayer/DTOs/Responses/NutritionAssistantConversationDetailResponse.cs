using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionAssistantConversationDetailResponse
    {
        public Guid ConversationId { get; set; }
        public string Title { get; set; } = string.Empty;
        public DateTimeOffset? CreatedAt { get; set; }
        public IReadOnlyList<NutritionAssistantMessageResponse> Messages { get; set; } = Array.Empty<NutritionAssistantMessageResponse>();
    }
}
