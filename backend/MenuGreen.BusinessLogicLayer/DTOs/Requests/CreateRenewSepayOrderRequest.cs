using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CreateRenewSepayOrderRequest
    {
        [Required]
        public Guid UserSubscriptionId { get; set; }

        public string? Note { get; set; }
    }
}
