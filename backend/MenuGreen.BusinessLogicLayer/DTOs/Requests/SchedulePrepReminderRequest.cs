using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SchedulePrepReminderRequest
    {
        [Required]
        public DateTime CookingTime { get; set; }

        [Range(0, 300)]
        public int PrepOffsetMinutes { get; set; } = 20;

        public string? Title { get; set; }
        public string? Body { get; set; }
    }
}
