using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class UserSubscription
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid SubscriptionPlanId { get; set; }
        public string Status { get; set; } = "Active";
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public DateTime? CancelledAt { get; set; }
        public DateTime? RenewedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual SubscriptionPlan? SubscriptionPlan { get; set; }
    }
}
