using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ScheduledReminderResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public string? Type { get; set; }
        public bool IsRead { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
        public DateTimeOffset? ScheduledAt { get; set; }
        public DateTimeOffset? SentAt { get; set; }
        public bool IsEnabled { get; set; }
    }
}
