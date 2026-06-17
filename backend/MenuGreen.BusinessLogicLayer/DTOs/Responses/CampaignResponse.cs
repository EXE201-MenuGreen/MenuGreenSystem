using System;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CampaignResponse
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string TargetSegment { get; set; } = string.Empty;
        public NotificationPayload Notification { get; set; } = new();
        public CampaignScheduleDto Schedule { get; set; } = new();
        public bool IsActive { get; set; }
        public string Status { get; set; } = "Draft";
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
