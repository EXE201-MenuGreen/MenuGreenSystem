using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class UserDashboardSummaryResponse
    {
        // Profile info
        public Guid UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? AvatarUrl { get; set; }
        
        // Subscription info
        public string? SubscriptionPlanName { get; set; }
        public int? SubscriptionDaysRemaining { get; set; }
        public bool IsPremium { get; set; }
        
        // Health profile
        public decimal? CurrentWeightKg { get; set; }
        public decimal? TargetWeightKg { get; set; }
        public decimal? HeightCm { get; set; }
        public decimal? BMI { get; set; }
        public decimal? TargetCalories { get; set; }
        
        // Today's nutrition
        public DateOnly Today { get; set; }
        public decimal TodayCaloriesConsumed { get; set; }
        public decimal TodayCaloriesTarget { get; set; }
        public decimal CaloriesProgressPercent { get; set; }
        
        // Streak & engagement
        public int TrackingStreak { get; set; }
        public int TotalMealLogsCount { get; set; }
        public int TotalDaysTracked { get; set; }
    }
}
