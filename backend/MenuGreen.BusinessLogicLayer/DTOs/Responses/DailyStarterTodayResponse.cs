using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class DailyStarterTodayResponse
    {
        public string WelcomeMessage { get; set; } = string.Empty;
        public string Quote { get; set; } = string.Empty;
        public string Author { get; set; } = string.Empty;
        public decimal CaloriesTarget { get; set; }
        public decimal CaloriesConsumed { get; set; }
        public decimal CaloriesRemaining { get; set; }
        public bool IsOnboardingComplete { get; set; }
        public bool HasLoggedToday { get; set; }
        public decimal? CurrentWeightKg { get; set; }
    }
}
