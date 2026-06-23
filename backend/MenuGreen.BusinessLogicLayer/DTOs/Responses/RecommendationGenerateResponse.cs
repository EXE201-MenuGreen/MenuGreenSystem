using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecommendationGenerateResponse
    {
        public Guid Id { get; set; }
        public List<RecommendationItemResponse> Items { get; set; } = new();
        public decimal TotalCalories { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
    }
}
