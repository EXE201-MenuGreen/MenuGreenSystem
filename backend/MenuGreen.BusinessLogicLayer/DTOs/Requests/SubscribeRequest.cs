using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SubscribeRequest
    {
        [Required]
        public Guid SubscriptionPlanId { get; set; }

        public string? PaymentMethod { get; set; }
        public string? Note { get; set; }
    }
}
