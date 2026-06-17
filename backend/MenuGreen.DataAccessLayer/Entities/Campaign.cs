using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Campaign
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string TargetSegment { get; set; } = string.Empty; // inactive_7_days, inactive_30_days, all_users
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public TimeOnly SendTime { get; set; }
        public bool IsActive { get; set; } = true;
        public string Status { get; set; } = "Draft"; // Draft, Running, Paused, Completed
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
