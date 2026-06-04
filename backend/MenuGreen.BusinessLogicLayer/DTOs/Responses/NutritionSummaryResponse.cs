using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionSummaryResponse
    {
        public string Period { get; set; } = string.Empty; // "day", "week", "month"
        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public decimal TotalCaloriesKcal { get; set; }
        public decimal TotalProteinG { get; set; }
        public decimal TotalCarbsG { get; set; }
        public decimal TotalFatG { get; set; }
        public int TotalMealLogs { get; set; }
        public decimal AvgCaloriesPerDay { get; set; }
        public decimal AvgProteinPerDay { get; set; }
        public decimal AvgCarbsPerDay { get; set; }
        public decimal AvgFatPerDay { get; set; }
    }
}
