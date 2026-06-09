namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsFunnelStepResponse
    {
        public string? Step { get; set; }
        public int Order { get; set; }
        public int Users { get; set; }
        public double ConversionFromPrevious { get; set; }
        public int DropOffFromPrevious { get; set; }
    }
}
