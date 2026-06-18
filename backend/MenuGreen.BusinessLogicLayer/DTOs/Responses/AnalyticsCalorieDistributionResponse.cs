namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsCalorieDistributionResponse
    {
        public CalorieDistributionDaily DailyDistribution { get; set; } = new();
        public List<WeeklyCalorieDistribution> WeeklyTrend { get; set; } = new();
        public string Recommendation { get; set; } = string.Empty;
    }

    public class CalorieDistributionDaily
    {
        public CalorieSegment BelowTarget { get; set; } = new();
        public CalorieSegment OnTarget { get; set; } = new();
        public CalorieSegment AboveTarget { get; set; } = new();
    }

    public class CalorieSegment
    {
        public decimal Percent { get; set; }
        public int UserCount { get; set; }
        public decimal AvgVariance { get; set; }
    }

    public class WeeklyCalorieDistribution
    {
        public string Week { get; set; } = string.Empty;
        public decimal BelowTarget { get; set; }
        public decimal OnTarget { get; set; }
        public decimal AboveTarget { get; set; }
    }
}
