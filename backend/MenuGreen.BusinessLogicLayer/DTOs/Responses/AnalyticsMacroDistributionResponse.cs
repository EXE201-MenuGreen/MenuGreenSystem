namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsMacroDistributionResponse
    {
        public MacroDistribution AverageDistribution { get; set; } = new();
        public Dictionary<string, MacroDistribution> DistributionByUserSegment { get; set; } = new();
        public string Recommendation { get; set; } = string.Empty;
    }

    public class MacroDistribution
    {
        public decimal ProteinPercent { get; set; }
        public decimal CarbsPercent { get; set; }
        public decimal FatPercent { get; set; }
    }
}
