using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class SmartScheduleResponse
    {
        public DateTime ExpectedMealTime { get; set; }
        public DateTime ReminderTime { get; set; }
        public int CookingTimeMinutes { get; set; }
        public int BufferMinutes { get; set; }
    }
}
