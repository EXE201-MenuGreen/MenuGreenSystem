using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class SubscriptionPlanResponse
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int DurationDays { get; set; }
        public int PriceVnd { get; set; }
        public string? FeatureGroup { get; set; }
        public bool IsActive { get; set; }
        public string TierLabel { get; set; } = string.Empty;
    }
}
