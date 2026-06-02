using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class SepayWebhookResultResponse
    {
        public bool Processed { get; set; }
        public bool IsDuplicate { get; set; }
        public string Message { get; set; } = string.Empty;
        public Guid? PaymentId { get; set; }
        public Guid? UserSubscriptionId { get; set; }
    }
}
