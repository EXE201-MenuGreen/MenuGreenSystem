using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class UserSubscriptionResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid SubscriptionPlanId { get; set; }
        public string SubscriptionPlanName { get; set; } = string.Empty;
        public string? FeatureGroup { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public DateTime? CancelledAt { get; set; }
        public DateTime? RenewedAt { get; set; }
        public int DaysRemaining { get; set; }
    }
}
