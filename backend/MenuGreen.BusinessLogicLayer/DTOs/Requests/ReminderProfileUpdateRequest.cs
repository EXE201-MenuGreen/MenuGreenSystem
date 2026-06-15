using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class ReminderProfileUpdateRequest
    {
        [Required]
        [RegularExpression(@"^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$", ErrorMessage = "Breakfast time must be in HH:mm format.")]
        public string OptimalBreakfastTime { get; set; } = "08:00";

        [Required]
        [RegularExpression(@"^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$", ErrorMessage = "Lunch time must be in HH:mm format.")]
        public string OptimalLunchTime { get; set; } = "12:00";

        [Required]
        [RegularExpression(@"^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$", ErrorMessage = "Dinner time must be in HH:mm format.")]
        public string OptimalDinnerTime { get; set; } = "19:00";
    }
}
