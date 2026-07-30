using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class CoachChatMessage
    {
        public Guid Id { get; set; }
        public Guid SenderId { get; set; }
        public Guid ReceiverId { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTimeOffset SentAt { get; set; }
        public DateTimeOffset? ReadAt { get; set; }

        public virtual User? Sender { get; set; }
        public virtual User? Receiver { get; set; }
    }
}
