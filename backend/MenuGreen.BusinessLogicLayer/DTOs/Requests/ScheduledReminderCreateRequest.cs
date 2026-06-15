using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ScheduledReminderCreateRequest
    {
        [Required]
        [StringLength(255)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [StringLength(1000)]
        public string Body { get; set; } = string.Empty;

        [Required]
        public DateTimeOffset ScheduledAt { get; set; }

        public string Type { get; set; } = "CUSTOM_REMINDER";
    }
}
