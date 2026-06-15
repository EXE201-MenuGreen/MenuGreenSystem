using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class ReminderProfile
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public TimeOnly OptimalBreakfastTime { get; set; } = new TimeOnly(8, 0);
        public TimeOnly OptimalLunchTime { get; set; } = new TimeOnly(12, 0);
        public TimeOnly OptimalDinnerTime { get; set; } = new TimeOnly(19, 0);
        public DateTime LastRecalculatedAt { get; set; } = DateTime.UtcNow;

        public virtual User? User { get; set; }
    }
}
