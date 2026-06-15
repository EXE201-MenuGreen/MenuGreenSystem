using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class GoalDriftAlert
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string AlertType { get; set; } = "CalorieDrift";
        public string Message { get; set; } = string.Empty;
        public decimal AverageValue { get; set; }
        public decimal TargetValue { get; set; }
        public decimal PercentDeviation { get; set; }
        public bool IsAcknowledged { get; set; } = false;
        public bool IsDismissed { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? AcknowledgedAt { get; set; }
        public DateTime? DismissedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
