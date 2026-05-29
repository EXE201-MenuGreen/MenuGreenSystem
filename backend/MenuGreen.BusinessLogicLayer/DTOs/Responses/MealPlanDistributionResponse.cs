using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanDistributionResponse
    {
        public Guid MealPlanId { get; set; }
        public string Message { get; set; } = string.Empty;
        public string TargetAudience { get; set; } = string.Empty;
        public DateTime DistributedAt { get; set; }
        public bool Completed { get; set; }
    }
}
