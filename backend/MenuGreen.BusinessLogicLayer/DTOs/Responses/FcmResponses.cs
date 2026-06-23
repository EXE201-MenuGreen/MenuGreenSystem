using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class DeviceTokenResponse
    {
        public Guid Id { get; set; }
        public string Token { get; set; } = string.Empty;
        public string? DeviceType { get; set; }
        public string? DeviceName { get; set; }
        public string? AppVersion { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastUsedAt { get; set; }
    }

    public class FcmSendResponse
    {
        public int SuccessCount { get; set; }
        public int FailureCount { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}
