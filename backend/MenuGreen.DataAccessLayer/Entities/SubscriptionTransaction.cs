using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class SubscriptionTransaction
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid UserSubscriptionId { get; set; }
        public string TransactionType { get; set; } = string.Empty;
        public int Amount { get; set; }
        public string Status { get; set; } = "Success";
        public string? Note { get; set; }
        public DateTime TransactionDate { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual UserSubscription? UserSubscription { get; set; }
    }
}
