using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class UserSubstitutePreferenceResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid OriginalIngredientId { get; set; }
        public string OriginalIngredientName { get; set; } = string.Empty;
        public Guid SubstituteIngredientId { get; set; }
        public string SubstituteIngredientName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}
