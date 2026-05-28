using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class WeightLogResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public decimal? WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
        public DateTime? RecordedAt { get; set; }
    }
}
