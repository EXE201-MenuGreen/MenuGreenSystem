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
        public int PlannedItemsCount { get; set; }
        public int ActualLogsCount { get; set; }
        public decimal CompletionRate { get; set; }
        public int SkippedItemsCount { get; set; }
        public List<MealPlanDashboardResponse> Days { get; set; } = new();
    }
}
