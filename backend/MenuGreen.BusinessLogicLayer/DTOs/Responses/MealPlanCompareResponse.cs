using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanCompareResponse
    {
        public DateOnly From { get; set; }
        public DateOnly To { get; set; }
        public int PlannedCalories { get; set; }
        public int ActualCalories { get; set; }
        public decimal CaloriePercent { get; set; }
        public int PlannedProtein { get; set; }
        public int ActualProtein { get; set; }
        public decimal ProteinPercent { get; set; }
        public int PlannedCarbs { get; set; }
        public int ActualCarbs { get; set; }
        public decimal CarbsPercent { get; set; }
        public int PlannedFat { get; set; }
        public int ActualFat { get; set; }
        public decimal FatPercent { get; set; }
        public int PlannedItemsCount { get; set; }
        public int ActualLogsCount { get; set; }
        public decimal CompletionRate { get; set; }
        public int SkippedItemsCount { get; set; }
        public int CompletedDays { get; set; }
        public int TotalDays { get; set; }
        public List<MealPlanWeekCompareResponse> WeeklyData { get; set; } = new();
        public List<MealPlanDashboardResponse> Days { get; set; } = new();
    }

    public class MealPlanWeekCompareResponse
    {
        public int WeekNumber { get; set; }
        public int PlannedCalories { get; set; }
        public int ActualCalories { get; set; }
        public decimal Percent { get; set; }
    }
}
