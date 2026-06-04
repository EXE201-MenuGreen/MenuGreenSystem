using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionTrendResponse
    {
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public List<DailyNutritionPoint> DailyData { get; set; } = new();
    }

    public class DailyNutritionPoint
    {
        public DateOnly Date { get; set; }
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
        public int MealCount { get; set; }
    }
}
