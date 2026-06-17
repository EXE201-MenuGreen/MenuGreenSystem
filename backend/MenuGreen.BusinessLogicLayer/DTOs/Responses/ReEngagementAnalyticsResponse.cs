using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ReEngagementAnalyticsResponse
    {
        public int TotalSent { get; set; }
        public int TotalOpened { get; set; }
        public int TotalClicked { get; set; }
        public int TotalActionCompleted { get; set; }
        public double OpenRate { get; set; }
        public double ClickRate { get; set; }
        public double ActionCompletionRate { get; set; }
    }
}
