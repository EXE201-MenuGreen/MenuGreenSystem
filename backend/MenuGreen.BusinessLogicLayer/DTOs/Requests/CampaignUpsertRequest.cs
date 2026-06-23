using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CampaignUpsertRequest
    {
        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string TargetSegment { get; set; } = string.Empty; // inactive_7_days, inactive_30_days, all_users

        [Required]
        public NotificationPayload Notification { get; set; } = new();

        [Required]
        public CampaignScheduleDto Schedule { get; set; } = new();

        public bool IsActive { get; set; } = true;
    }

    public class CampaignScheduleDto
    {
        [Required]
        public DateOnly StartDate { get; set; }

        [Required]
        public DateOnly EndDate { get; set; }

        [Required]
        public TimeOnly SendTime { get; set; }
    }
}
