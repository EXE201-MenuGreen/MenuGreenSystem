using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealDaySummaryResponse
    {
        public string Date { get; set; } = string.Empty;
        public decimal TotalCalories { get; set; }
        public decimal TotalProteinG { get; set; }
        public decimal TotalCarbsG { get; set; }
        public decimal TotalFatG { get; set; }
        public decimal TargetCalories { get; set; }
        public decimal TargetProteinG { get; set; }
        public decimal TargetCarbsG { get; set; }
        public decimal TargetFatG { get; set; }
        public decimal CaloriesDeviation { get; set; }
        public decimal ProteinDeviation { get; set; }
        public decimal CarbsDeviation { get; set; }
        public decimal FatDeviation { get; set; }
        public bool HasWarning { get; set; }
        public List<string> WarningMessages { get; set; } = new();
        /// <summary>Percent of daily calorie target consumed (from NutritionSnapshot rollup).</summary>
        public decimal? GoalCompletionPercent { get; set; }
        public bool HasSnapshot { get; set; }
        public List<MealLogResponse> MealLogs { get; set; } = new();
    }
}
