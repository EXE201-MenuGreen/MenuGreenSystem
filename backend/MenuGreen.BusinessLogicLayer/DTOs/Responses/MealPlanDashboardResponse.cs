using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanDashboardResponse
    {
        public DateOnly Date { get; set; }
        public int TotalPlannedCalories { get; set; }
        public int TotalActualCalories { get; set; }
        public int PlannedProtein { get; set; }
        public int ActualProtein { get; set; }
        public int PlannedCarbs { get; set; }
        public int ActualCarbs { get; set; }
        public int PlannedFat { get; set; }
        public int ActualFat { get; set; }
        public int PlannedItemsCount { get; set; }
        public int CompletedItemsCount { get; set; }
        public int SkippedItemsCount { get; set; }
        public decimal CompletionRate => PlannedItemsCount == 0 ? 0 : Math.Round((decimal)CompletedItemsCount / PlannedItemsCount * 100m, 2);
        public List<MealPlanItemResponse> Items { get; set; } = new();
        public List<MealLogResponse> ActualLogs { get; set; } = new();
    }
}
