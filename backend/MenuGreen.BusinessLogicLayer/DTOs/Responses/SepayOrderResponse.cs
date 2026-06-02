using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class SepayOrderResponse
    {
        public Guid PaymentId { get; set; }
        public Guid UserSubscriptionId { get; set; }
        public int AmountVnd { get; set; }
        public string Status { get; set; } = string.Empty;
        public string ProviderOrderCode { get; set; } = string.Empty;
        public string TransferContent { get; set; } = string.Empty;
        public DateTimeOffset ExpiredAt { get; set; }
    }
}
