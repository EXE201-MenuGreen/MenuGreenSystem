using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsInactiveUserResponse
    {
        public Guid UserId { get; set; }
        public DateTimeOffset? LastActivityAt { get; set; }
    }
}
