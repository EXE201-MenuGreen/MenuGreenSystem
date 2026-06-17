using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AiMessageResponse
    {
        public Guid Id { get; set; }
        public Guid ConversationId { get; set; }
        public string Role { get; set; } = string.Empty; // user, assistant
        public string Content { get; set; } = string.Empty;
        public int? TokensUsed { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
        public string? Feedback { get; set; } // logs like/dislike feedback
    }
}
