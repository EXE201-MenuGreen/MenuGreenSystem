using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class NotificationSendBulkRequest
    {
        [Required]
        public List<Guid> UserIds { get; set; } = new();

        [Required]
        public NotificationPayload Notification { get; set; } = new();

        public DateTimeOffset? ScheduleAt { get; set; }
    }

    public class NotificationPayload
    {
        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [StringLength(1000)]
        public string Body { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Type { get; set; } = string.Empty;
    }
}
