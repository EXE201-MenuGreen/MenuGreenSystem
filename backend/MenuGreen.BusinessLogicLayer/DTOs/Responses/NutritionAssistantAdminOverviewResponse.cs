using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionAssistantAdminOverviewResponse
    {
        public NutritionAssistantBridgeHealthResponse BridgeHealth { get; set; } = new();
        public int TotalAiProfiles { get; set; }
        public int TotalConversations { get; set; }
        public int TotalMessages { get; set; }
        public int MessagesLast7Days { get; set; }
        public DateTimeOffset? LatestConversationAt { get; set; }
        public IReadOnlyList<NutritionAssistantConversationSummaryResponse> RecentConversations { get; set; } = Array.Empty<NutritionAssistantConversationSummaryResponse>();
    }
}
