using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateAiProfileRequest
    {
        public string? Preferences { get; set; } // JSON or comma-separated string
        public string? DislikedFoods { get; set; } // JSON or comma-separated string
        public string? EatingPattern { get; set; } // JSON or text
    }
}
