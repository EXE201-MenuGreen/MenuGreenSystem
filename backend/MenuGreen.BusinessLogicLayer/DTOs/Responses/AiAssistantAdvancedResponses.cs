using System;
using System.Collections.Generic;
using System.Text.Json;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AiMealPlanActionResponse
    {
        public string Prompt { get; set; } = string.Empty;
        public DateTimeOffset GeneratedAt { get; set; }
        public NutritionAssistantMealPlan7dResponse MealPlan { get; set; } = new();
    }

    public class AiFoodReplacementActionResponse
    {
        public Guid OriginalFoodId { get; set; }
        public string OriginalFoodName { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
        public JsonElement Recommendations { get; set; }
        public DateTimeOffset GeneratedAt { get; set; }
    }

    public class AiBudgetOptimizationResponse
    {
        public int BudgetPerMealVnd { get; set; }
        public decimal TargetCaloriesPerMeal { get; set; }
        public JsonElement Recommendations { get; set; }
        public DateTimeOffset GeneratedAt { get; set; }
    }

    public class AiAssistantInsightsResponse
    {
        public int TotalUserMessages { get; set; }
        public DateTimeOffset? FirstMessageAt { get; set; }
        public DateTimeOffset? LastMessageAt { get; set; }
        public IReadOnlyList<AiTopicInsightResponse> Topics { get; set; } = Array.Empty<AiTopicInsightResponse>();
        public IReadOnlyDictionary<string, double> InterestDistribution { get; set; } =
            new Dictionary<string, double>();
    }

    public class AiTopicInsightResponse
    {
        public string Topic { get; set; } = string.Empty;
        public int Count { get; set; }
        public double Percentage { get; set; }
    }

    public class AiAssistantUsageResponse
    {
        public int TotalConversations { get; set; }
        public int TotalMessages { get; set; }
        public int UserMessages { get; set; }
        public int AssistantMessages { get; set; }
        public int ActiveDays { get; set; }
        public int MessagesThisWeek { get; set; }
        public int MessagesThisMonth { get; set; }
        public DateTimeOffset? LastUsed { get; set; }
        public IReadOnlyDictionary<string, int> DailyMessagesLast7Days { get; set; } =
            new Dictionary<string, int>();
    }
}
