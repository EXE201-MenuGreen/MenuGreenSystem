using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AiConversationResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Title { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
    }
}
