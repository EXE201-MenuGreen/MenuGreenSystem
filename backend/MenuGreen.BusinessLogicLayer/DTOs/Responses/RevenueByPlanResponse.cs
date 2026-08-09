namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RevenueByPlanResponse
    {
        public List<RevenueByPlanItem> Plans { get; set; } = new();
        public int TotalRevenue { get; set; }
        public int TotalSubscribers { get; set; }
    }

    public class RevenueByPlanItem
    {
        public string PlanName { get; set; } = string.Empty;
        public string PlanKey { get; set; } = string.Empty;
        public int Revenue { get; set; }
        public int Subscribers { get; set; }
        public double Percent { get; set; }
        public string Color { get; set; } = string.Empty;
    }
}
