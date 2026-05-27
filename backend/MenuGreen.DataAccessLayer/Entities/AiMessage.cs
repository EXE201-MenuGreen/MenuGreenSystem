using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class AiMessage
    {
        public Guid Id { get; set; }
        public Guid ConversationId { get; set; }
        public string? Role { get; set; }
        public string? Content { get; set; }
        public int? TokensUsed { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        public virtual AiConversation? Conversation { get; set; }
    }
}
