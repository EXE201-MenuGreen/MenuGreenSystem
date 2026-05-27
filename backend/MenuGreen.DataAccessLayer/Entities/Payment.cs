using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Payment
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? SubscriptionId { get; set; }
        public int? AmountVnd { get; set; }
        public string? Status { get; set; }
        public string? PaymentMethod { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual Subscription? Subscription { get; set; }
    }
}
