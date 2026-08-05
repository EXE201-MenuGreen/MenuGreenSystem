using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NotificationResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public string? Type { get; set; }
        public string? ActionUrl { get; set; }
        public bool IsRead { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset? ScheduledAt { get; set; }
        public DateTimeOffset? SentAt { get; set; }
        public DateTimeOffset? ReadAt { get; set; }
        public bool IsDismissed { get; set; }
        public DateTimeOffset? DismissedAt { get; set; }
        public DateTimeOffset? ClickedAt { get; set; }
        public DateTimeOffset? ActionCompletedAt { get; set; }
    }
}
