using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class DeviceTokenRegisterRequest
    {
        [Required]
        [StringLength(4096)]
        public string Token { get; set; } = string.Empty;

        [StringLength(32)]
        public string? DeviceType { get; set; }

        [StringLength(200)]
        public string? DeviceName { get; set; }

        [StringLength(50)]
        public string? AppVersion { get; set; }
    }

    public class FcmSendRequest
    {
        public Guid UserId { get; set; }
        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [StringLength(2000)]
        public string Body { get; set; } = string.Empty;

        [StringLength(4096)]
        public string? Data { get; set; }
    }

    public class FcmSendBulkRequest
    {
        [Required]
        [MinLength(1)]
        [MaxLength(500)]
        public List<Guid> UserIds { get; set; } = new();

        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [StringLength(2000)]
        public string Body { get; set; } = string.Empty;

        [StringLength(4096)]
        public string? Data { get; set; }
    }
}
