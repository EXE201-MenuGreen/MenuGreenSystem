using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanStatusRequest
    {
        [Required]
        public bool IsActive { get; set; }
    }
}
