using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NotificationSettingResponse
    {
        public Guid UserId { get; set; }
        public bool MealReminderEnabled { get; set; }
        public int MealReminderOffsetMinutes { get; set; }
        public bool PrepReminderEnabled { get; set; }
        public int PrepReminderOffsetMinutes { get; set; }
        public bool InAppEnabled { get; set; }
        public bool PushEnabled { get; set; }
    }
}
