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

        /// <summary>Mã thanh toán (DH-...) — khớp webhook SePay.</summary>
        public string TransferContent { get; set; } = string.Empty;

        /// <summary>Nội dung chuyển khoản đầy đủ trong QR (có thể gồm prefix SEVQR/TKP theo ngân hàng).</summary>
        public string TransferMemo { get; set; } = string.Empty;

        /// <summary>URL ảnh QR động (qr.sepay.vn) — frontend hiển thị bằng Image/img với URL này.</summary>
        public string QrImageUrl { get; set; } = string.Empty;

        public SepayReceiverInfo Receiver { get; set; } = new();
        public DateTimeOffset ExpiredAt { get; set; }
    }
}
