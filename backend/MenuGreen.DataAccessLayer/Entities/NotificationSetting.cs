using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class NotificationSetting
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public bool MealReminderEnabled { get; set; } = true;
        public int MealReminderOffsetMinutes { get; set; } = 30;
        public bool PrepReminderEnabled { get; set; } = true;
        public int PrepReminderOffsetMinutes { get; set; } = 20;
        public bool InAppEnabled { get; set; } = true;
        public bool PushEnabled { get; set; } = false;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
