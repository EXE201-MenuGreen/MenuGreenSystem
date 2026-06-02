using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Payment
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? UserSubscriptionId { get; set; }
        public int AmountVnd { get; set; }
        public string Status { get; set; } = "PENDING";
        public string PaymentMethod { get; set; } = "SEPAY";
        public string Provider { get; set; } = "SEPAY";
        public string ProviderOrderCode { get; set; } = string.Empty;
        public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
        public DateTimeOffset? UpdatedAt { get; set; }
        public DateTimeOffset? ExpiredAt { get; set; }
        public DateTimeOffset? PaidAt { get; set; }

        public virtual User? User { get; set; }
        public virtual UserSubscription? UserSubscription { get; set; }
    }
}
