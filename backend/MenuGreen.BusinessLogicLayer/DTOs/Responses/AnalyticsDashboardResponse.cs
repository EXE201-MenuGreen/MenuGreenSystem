namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsDashboardResponse
    {
        public int TotalEvents { get; set; }
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int ActiveUsersLast7Days { get; set; }
        public int MealLoggedEvents { get; set; }
        public int NotificationOpenedEvents { get; set; }
        public int SubscriptionStartedEvents { get; set; }
    }
}
