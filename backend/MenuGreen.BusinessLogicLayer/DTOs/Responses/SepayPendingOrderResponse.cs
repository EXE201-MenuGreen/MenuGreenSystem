using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    /// <summary>Đơn SePay đang chờ thanh toán (PENDING), kèm thông tin gói để app hiển thị QR tiếp tục.</summary>
    public class SepayPendingOrderResponse
    {
        public Guid PaymentId { get; set; }
        public Guid UserSubscriptionId { get; set; }
        public Guid SubscriptionPlanId { get; set; }
        public string SubscriptionPlanName { get; set; } = string.Empty;

        /// <summary>Subscribe — đăng ký mới; Renew — gia hạn gói đang active.</summary>
        public string OrderType { get; set; } = string.Empty;

        public int AmountVnd { get; set; }
        public string Status { get; set; } = string.Empty;
        public string ProviderOrderCode { get; set; } = string.Empty;
        public string TransferContent { get; set; } = string.Empty;
        public string TransferMemo { get; set; } = string.Empty;
        public string QrImageUrl { get; set; } = string.Empty;
        public SepayReceiverInfo Receiver { get; set; } = new();
        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset ExpiredAt { get; set; }
    }
}
