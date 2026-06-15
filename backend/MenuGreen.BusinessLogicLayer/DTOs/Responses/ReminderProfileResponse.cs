using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ReminderProfileResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string OptimalBreakfastTime { get; set; } = "08:00";
        public string OptimalLunchTime { get; set; } = "12:00";
        public string OptimalDinnerTime { get; set; } = "19:00";
        public DateTime LastRecalculatedAt { get; set; }
    }
}
