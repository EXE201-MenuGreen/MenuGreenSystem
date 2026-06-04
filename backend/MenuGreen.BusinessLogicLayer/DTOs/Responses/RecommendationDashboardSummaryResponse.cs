using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationDashboardSummaryResponse
    {
        public List<RecommendationItemSummary> LatestRecommendations { get; set; } = new();
        public int TotalRecommendations { get; set; }
        public DateOnly? LastGeneratedDate { get; set; }
        public string? PersonalizedMessage { get; set; }
    }

    public class RecommendationItemSummary
    {
        public Guid Id { get; set; }
        public string Type { get; set; } = string.Empty; // "Food", "Recipe", "MealPlan"
        public string? ItemName { get; set; }
        public decimal? MatchScore { get; set; }
        public DateOnly RecommendedDate { get; set; }
    }
}
