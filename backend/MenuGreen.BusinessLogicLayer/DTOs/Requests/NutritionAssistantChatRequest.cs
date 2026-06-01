using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class NutritionAssistantChatRequest
    {
        public Guid? ConversationId { get; set; }

        [Required]
        [MinLength(1)]
        [MaxLength(4000)]
        public string Message { get; set; } = string.Empty;

        [MaxLength(20)]
        public string Language { get; set; } = "vi";

        public bool Stream { get; set; } = false;
    }
}
