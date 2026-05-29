using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CancelSubscriptionRequest
    {
        [Required]
        public Guid UserSubscriptionId { get; set; }

        public string? Reason { get; set; }
    }
}
