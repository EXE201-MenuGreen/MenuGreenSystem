using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SmartScheduleRequest
    {
        [Required]
        public DateTime ExpectedMealTime { get; set; }

        [Range(0, int.MaxValue)]
        public int CookingTimeMinutes { get; set; }

        public int BufferMinutes { get; set; } = 5;

        [Range(1, 100)]
        public int Limit { get; set; } = 5;
    }
}
