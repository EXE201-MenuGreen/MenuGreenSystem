using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class GoalDriftAlertResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string AlertType { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public decimal AverageValue { get; set; }
        public decimal TargetValue { get; set; }
        public decimal PercentDeviation { get; set; }
        public bool IsAcknowledged { get; set; }
        public bool IsDismissed { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? AcknowledgedAt { get; set; }
        public DateTime? DismissedAt { get; set; }
    }
}
