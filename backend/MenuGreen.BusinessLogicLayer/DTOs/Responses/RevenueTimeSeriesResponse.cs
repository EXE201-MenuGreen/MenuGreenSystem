namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RevenueTimeSeriesResponse
    {
        public List<RevenueTimeSeriesPoint> Points { get; set; } = new();
        public int TotalRevenue { get; set; }
        public int TransactionCount { get; set; }
        public double ChangeVsPrevious { get; set; }
    }

    public class RevenueTimeSeriesPoint
    {
        public DateTime Date { get; set; }
        public int TotalRevenue { get; set; }
        public int SubscribeRevenue { get; set; }
        public int RenewRevenue { get; set; }
        public int TransactionCount { get; set; }
    }
}
