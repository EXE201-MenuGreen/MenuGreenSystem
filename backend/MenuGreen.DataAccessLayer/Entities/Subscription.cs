using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Subscription
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid PlanId { get; set; }
        public string? Status { get; set; }
        public bool? AutoRenew { get; set; }
        public DateTimeOffset? StartedAt { get; set; }
        public DateTimeOffset? ExpiresAt { get; set; }

        public virtual User? User { get; set; }
        public virtual SubscriptionPlan? Plan { get; set; }
    }
}
