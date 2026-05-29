using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class SubscriptionPlanStatusRequest
    {
        [Required]
        public bool IsActive { get; set; }
    }
}
