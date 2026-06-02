using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateHealthGoalRequest
    {
        [Required]
        [MinLength(1)]
        public string Goal { get; set; } = string.Empty;
    }
}
