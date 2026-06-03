using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationExplainResponse
    {
        public Guid RecommendationId { get; set; }
        public IReadOnlyList<string> Reasons { get; set; } = Array.Empty<string>();
        public IReadOnlyList<string> MatchedRules { get; set; } = Array.Empty<string>();
        public IReadOnlyList<string> UsedContext { get; set; } = Array.Empty<string>();
    }
}
