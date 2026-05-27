using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class SepayTransaction
    {
        public Guid Id { get; set; }
        public Guid PaymentId { get; set; }
        public string? TransactionCode { get; set; }
        public string? BankAccount { get; set; }
        public int? TransferAmount { get; set; }
        public string? TransferContent { get; set; }
        public DateTimeOffset? TransactionTime { get; set; }
        public string? Status { get; set; }

        public virtual Payment? Payment { get; set; }
    }
}
