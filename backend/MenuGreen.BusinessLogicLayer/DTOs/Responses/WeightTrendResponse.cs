using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class WeightTrendResponse
    {
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
        public decimal? InitialWeightKg { get; set; }
        public decimal? LatestWeightKg { get; set; }
        public decimal? WeightChangeKg { get; set; }
        public decimal? AverageWeightKg { get; set; }
        public List<WeightPoint> WeightData { get; set; } = new();
    }

    public class WeightPoint
    {
        public DateOnly Date { get; set; }
        public decimal WeightKg { get; set; }
        public decimal? BodyFatPercent { get; set; }
    }
}
