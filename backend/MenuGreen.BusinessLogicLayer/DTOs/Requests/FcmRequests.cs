using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class DeviceTokenRegisterRequest
    {
        public string Token { get; set; } = string.Empty;
        public string? DeviceType { get; set; }
        public string? DeviceName { get; set; }
        public string? AppVersion { get; set; }
    }

    public class FcmSendRequest
    {
        public Guid UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string? Data { get; set; }
    }

    public class FcmSendBulkRequest
    {
        public List<Guid> UserIds { get; set; } = new();
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string? Data { get; set; }
    }
}
