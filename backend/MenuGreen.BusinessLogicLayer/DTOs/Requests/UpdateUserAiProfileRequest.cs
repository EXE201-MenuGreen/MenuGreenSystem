namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateUserAiProfileRequest
    {
        /// <summary>JSON or comma-separated eating preferences from onboarding.</summary>
        public string? Preferences { get; set; }

        public string? DislikedFoods { get; set; }

        /// <summary>User segment: gym, office, general.</summary>
        public string? EatingPattern { get; set; }

        /// <summary>True when user completed allergy step with no selections.</summary>
        public bool? AllergiesAcknowledged { get; set; }
    }
}
