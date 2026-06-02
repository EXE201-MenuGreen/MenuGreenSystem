using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CreateSepayOrderRequest
    {
        [Required]
        public Guid SubscriptionPlanId { get; set; }

        public string? Note { get; set; }
    }
}
