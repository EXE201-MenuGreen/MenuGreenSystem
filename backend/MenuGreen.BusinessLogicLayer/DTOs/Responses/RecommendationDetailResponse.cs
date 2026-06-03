using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationDetailResponse
    {
        public Guid Id { get; set; }
        public string? Type { get; set; }
        public string? Input { get; set; }
        public string? Output { get; set; }
        public decimal? Confidence { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }
    }
}
