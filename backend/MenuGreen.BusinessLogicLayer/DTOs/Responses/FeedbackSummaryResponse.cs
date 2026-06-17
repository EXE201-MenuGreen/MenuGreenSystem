using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class FeedbackSummaryResponse
    {
        public int TotalFeedbacks { get; set; }
        public int PositiveCount { get; set; }
        public int NegativeCount { get; set; }
        public double PositiveRate { get; set; }
        public Dictionary<string, MealTypeFeedbackStatsDto> ByMealType { get; set; } = new();
    }

    public class MealTypeFeedbackStatsDto
    {
        public int Positive { get; set; }
        public int Negative { get; set; }
        public double Rate { get; set; }
    }
}
