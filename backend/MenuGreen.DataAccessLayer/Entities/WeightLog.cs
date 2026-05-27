using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class WeightLog
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public DateTime? RecordedAt { get; set; }

        public virtual User? User { get; set; }
    }
}
