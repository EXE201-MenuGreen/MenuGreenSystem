using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class AdminGrantMembershipRequest
    {
        [Required]
        public Guid SubscriptionPlanId { get; set; }

        [Range(1, 3650)]
        public int DurationDays { get; set; } = 30;

        public DateTime? StartDate { get; set; }

        [MaxLength(500)]
        public string? Note { get; set; }
    }

    public class AdminExtendMembershipRequest
    {
        [Range(1, 3650)]
        public int DurationDays { get; set; } = 30;

        [MaxLength(500)]
        public string? Note { get; set; }
    }

    public class AdminRevokeMembershipRequest
    {
        [Required]
        [MinLength(3)]
        [MaxLength(500)]
        public string Reason { get; set; } = string.Empty;
    }
}
