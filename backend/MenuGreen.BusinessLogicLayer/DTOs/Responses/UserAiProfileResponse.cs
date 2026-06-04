using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class UserAiProfileResponse
    {
        public Guid UserId { get; set; }
        public string? Preferences { get; set; }
        public string? DislikedFoods { get; set; }
        public string? EatingPattern { get; set; }
        public bool AllergiesAcknowledged { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
