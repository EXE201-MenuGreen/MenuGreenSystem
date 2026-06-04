using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class SubscriptionPlanStatusResponse
    {
        public Guid PlanId { get; set; }
        public string PlanName { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public string StatusMessage { get; set; } = string.Empty;
    }
}
