namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RevenueDashboardMetricsResponse
    {
        public int TotalRevenueVnd { get; set; }
        public int SubscribeRevenueVnd { get; set; }
        public int RenewRevenueVnd { get; set; }
        public int TransactionCount { get; set; }
    }
}
