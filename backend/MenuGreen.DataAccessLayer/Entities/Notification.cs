using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class Notification
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public string? Type { get; set; }
        public string? ActionUrl { get; set; }
        public bool IsRead { get; set; } = false;
        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset? ScheduledAt { get; set; }
        public DateTimeOffset? SentAt { get; set; }
        public DateTimeOffset? ReadAt { get; set; }

        public Guid? CampaignId { get; set; }
        public virtual Campaign? Campaign { get; set; }
        public DateTimeOffset? ClickedAt { get; set; }
        public DateTimeOffset? ActionCompletedAt { get; set; }

        public bool IsDismissed { get; set; } = false;
        public DateTimeOffset? DismissedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
