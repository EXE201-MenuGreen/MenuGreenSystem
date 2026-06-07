using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanAdherenceResponse
    {
        public DateOnly Date { get; set; }
        public int PlannedKcal { get; set; }
        public decimal ActualKcal { get; set; }
        public decimal? DeviationPercent { get; set; }
        public int CompletedCount { get; set; }
        public int TotalCount { get; set; }
    }
}
