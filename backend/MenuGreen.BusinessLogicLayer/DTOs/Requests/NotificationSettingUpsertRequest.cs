using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class NotificationSettingUpsertRequest
    {
        public bool MealReminderEnabled { get; set; } = true;

        [Range(0, 1440)]
        public int MealReminderOffsetMinutes { get; set; } = 30;

        public bool PrepReminderEnabled { get; set; } = true;

        [Range(0, 1440)]
        public int PrepReminderOffsetMinutes { get; set; } = 20;

        public bool InAppEnabled { get; set; } = true;
        public bool PushEnabled { get; set; } = false;
    }
}
