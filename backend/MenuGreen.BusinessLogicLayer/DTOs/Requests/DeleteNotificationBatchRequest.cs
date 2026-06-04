using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class DeleteNotificationBatchRequest
    {
        [Required]
        [MinLength(1, ErrorMessage = "NotificationIds list cannot be empty")]
        public List<Guid> NotificationIds { get; set; } = new();
    }
}
