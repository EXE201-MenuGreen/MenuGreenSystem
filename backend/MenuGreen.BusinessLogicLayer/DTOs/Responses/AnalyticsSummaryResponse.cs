using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsSummaryResponse
    {
        public int TotalEvents { get; set; }
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int MealLoggedEvents { get; set; }
        public int NotificationOpenedEvents { get; set; }
        public int SubscriptionStartedEvents { get; set; }
        public DateTimeOffset From { get; set; }
        public DateTimeOffset To { get; set; }
    }
}
