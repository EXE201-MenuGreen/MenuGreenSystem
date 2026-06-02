using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class SepayTransaction
    {
        public Guid Id { get; set; }
        public Guid PaymentId { get; set; }
        public string TransactionCode { get; set; } = string.Empty;
        public string? BankAccount { get; set; }
        public int TransferAmount { get; set; }
        public string TransferContent { get; set; } = string.Empty;
        public DateTimeOffset TransactionTime { get; set; } = DateTimeOffset.UtcNow;
        public string Status { get; set; } = "RECEIVED";
        public string? RawPayloadJson { get; set; }
        public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

        public virtual Payment? Payment { get; set; }
    }
}
