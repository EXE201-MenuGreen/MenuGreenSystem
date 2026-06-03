using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationHistoryResponse
    {
        public Guid Id { get; set; }
        public string? Type { get; set; }
        public string? Summary { get; set; }
        public decimal? Confidence { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }
    }
}
