namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsNutritionDashboardResponse
    {
        public NutritionSummarySection Summary { get; set; } = new();
        public NutritionTargets Targets { get; set; } = new();
        public NutritionComparisons Comparisons { get; set; } = new();
    }

    public class NutritionSummarySection
    {
        public int TotalMealLogs { get; set; }
        public decimal TotalCaloriesConsumed { get; set; }
        public decimal TotalProteinG { get; set; }
        public decimal TotalCarbsG { get; set; }
        public decimal TotalFatG { get; set; }
        public decimal AvgCaloriesPerUserPerDay { get; set; }
        public decimal AvgProteinPerUserPerDay { get; set; }
        public decimal AvgCarbsPerUserPerDay { get; set; }
        public decimal AvgFatPerUserPerDay { get; set; }
        public int ActiveUsersCount { get; set; }
    }

    public class NutritionTargets
    {
        public decimal AvgCalorieTarget { get; set; }
        public decimal AvgProteinTarget { get; set; }
        public decimal AvgCarbTarget { get; set; }
        public decimal AvgFatTarget { get; set; }
    }

    public class NutritionComparisons
    {
        public decimal MealLogsChange { get; set; }
        public decimal CaloriesChange { get; set; }
        public decimal ProteinChange { get; set; }
        public decimal CarbsChange { get; set; }
        public decimal FatChange { get; set; }
    }
}
