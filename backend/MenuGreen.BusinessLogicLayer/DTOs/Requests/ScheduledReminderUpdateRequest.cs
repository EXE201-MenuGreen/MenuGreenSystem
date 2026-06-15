using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ScheduledReminderUpdateRequest
    {
        [StringLength(255)]
        public string? Title { get; set; }

        [StringLength(1000)]
        public string? Body { get; set; }

        public DateTimeOffset? ScheduledAt { get; set; }

        public bool? IsEnabled { get; set; }
    }
}
