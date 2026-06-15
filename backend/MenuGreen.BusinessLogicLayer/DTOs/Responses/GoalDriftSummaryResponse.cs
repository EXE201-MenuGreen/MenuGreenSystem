using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class GoalDriftSummaryResponse
    {
        public Guid UserId { get; set; }
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public decimal AvgCaloriesKcal { get; set; }
        public decimal TargetCaloriesKcal { get; set; }
        public decimal CalorieDeviationPercent { get; set; }
        public List<string> ActiveAlertsSummary { get; set; } = new();
    }
}
