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

        /// <summary>Vietnamese taste region preference: north, central, south.</summary>
        public string? VietnamRegion { get; set; }

        /// <summary>Typical meal context: eat-out, home-cooked, mixed.</summary>
        public string? MealContext { get; set; }

        /// <summary>Preferred budget per meal in VND.</summary>
        public int? BudgetPerMealVnd { get; set; }

        /// <summary>Comma-separated or JSON array of preferred local portion units.</summary>
        public string? PreferredPortionUnits { get; set; }
    }
}
