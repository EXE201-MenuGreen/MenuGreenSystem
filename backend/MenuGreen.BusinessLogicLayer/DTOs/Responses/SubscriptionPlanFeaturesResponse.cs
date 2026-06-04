using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class SubscriptionPlanFeaturesResponse
    {
        public Guid PlanId { get; set; }
        public string PlanName { get; set; } = string.Empty;
        public string? FeatureGroup { get; set; }
        public List<string> Features { get; set; } = new();
    }
}
