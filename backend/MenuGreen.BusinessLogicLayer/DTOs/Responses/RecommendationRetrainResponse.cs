using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationRetrainResponse
    {
        public bool DryRun { get; set; }
        public bool Applied { get; set; }
        public string Status { get; set; } = string.Empty;
        public int HistoriesCount { get; set; }
        public int FeedbackCount { get; set; }
        public int PositiveCount { get; set; }
        public int NegativeCount { get; set; }
        public DateTimeOffset EvaluatedAt { get; set; }
        public IReadOnlyDictionary<string, RecommendationRuleTuningResponse> RuleWeights { get; set; } =
            new Dictionary<string, RecommendationRuleTuningResponse>();
        public IReadOnlyList<string> PreferredItems { get; set; } = Array.Empty<string>();
        public IReadOnlyList<string> AvoidedItems { get; set; } = Array.Empty<string>();
        public string Message { get; set; } = string.Empty;
    }

    public class RecommendationRuleTuningResponse
    {
        public int Samples { get; set; }
        public double AverageRating { get; set; }
        public double Weight { get; set; }
    }
}
