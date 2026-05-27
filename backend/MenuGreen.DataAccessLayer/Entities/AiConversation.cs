using System;
using System.Collections.Generic;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class AiConversation
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Title { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        public virtual User? User { get; set; }
        public virtual ICollection<AiMessage> Messages { get; set; } = new List<AiMessage>();
    }
}
