using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class NotificationSendEventRequest
    {
        [Required]
        [StringLength(100)]
        public string EventType { get; set; } = string.Empty; // meal_time, subscription_expiring, weight_reminder, meal_not_logged

        [Required]
        public Guid UserId { get; set; }

        public Dictionary<string, object>? Context { get; set; }
    }
}
