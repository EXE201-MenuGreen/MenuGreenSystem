namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsUserInsightsResponse
    {
        public EngagementMetrics EngagementMetrics { get; set; } = new();
        public DietQuality DietQuality { get; set; } = new();
        public NutrientAdequacy NutrientAdequacy { get; set; } = new();
    }

    public class EngagementMetrics
    {
        public decimal AvgMealLogsPerUserPerWeek { get; set; }
        public decimal AvgMealsLoggedPerDay { get; set; }
        public int UsersLoggingAllMeals { get; set; }
        public int UsersLoggingPartialMeals { get; set; }
        public StreakStats StreakStats { get; set; } = new();
    }

    public class StreakStats
    {
        public decimal AvgStreakDays { get; set; }
        public int MaxStreakDays { get; set; }
        public int UsersWithStreakOver7Days { get; set; }
    }

    public class DietQuality
    {
        public decimal AvgDietScore { get; set; }
        public int UsersWithGoodDiet { get; set; }
        public int UsersWithPoorDiet { get; set; }
        public int ImprovingUsers { get; set; }
        public int DecliningUsers { get; set; }
    }

    public class NutrientAdequacy
    {
        public decimal AdequateProtein { get; set; }
        public decimal AdequateFiber { get; set; }
        public decimal AdequateVitamins { get; set; }
        public decimal HighSodium { get; set; }
        public decimal LowWaterIntake { get; set; }
    }
}
