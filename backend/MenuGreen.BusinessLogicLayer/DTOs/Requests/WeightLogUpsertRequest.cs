using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class WeightLogUpsertRequest
    {
        [Required]
        public decimal WeightKg { get; set; }

        public decimal? BodyFatPercent { get; set; }
        public DateTime? RecordedAt { get; set; }
    }
}
