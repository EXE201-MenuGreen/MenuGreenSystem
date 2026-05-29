using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ScheduleMealReminderRequest
    {
        [Required]
        public DateTime MealTime { get; set; }

        [Range(0, 300)]
        public int CookingTimeMinutes { get; set; }

        public string? Title { get; set; }
        public string? Body { get; set; }
    }
}
