using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CoachChatMessageResponse
    {
        public Guid Id { get; set; }
        public Guid SenderId { get; set; }
        public Guid ReceiverId { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTimeOffset SentAt { get; set; }
        public DateTimeOffset? ReadAt { get; set; }
        public bool IsMine { get; set; }
    }

    public class CoachChatPartnerResponse
    {
        public Guid PartnerId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public string? LastMessage { get; set; }
        public DateTimeOffset? LastMessageAt { get; set; }
        public int UnreadCount { get; set; }
    }
}
