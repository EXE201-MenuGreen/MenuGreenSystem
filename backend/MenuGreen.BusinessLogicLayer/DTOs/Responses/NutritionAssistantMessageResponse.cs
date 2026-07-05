using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionAssistantMessageResponse
    {
        public Guid MessageId { get; set; }
        public string Role { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public int? TokensUsed { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }
    }
}
