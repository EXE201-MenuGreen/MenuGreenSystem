using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class BudgetRequestUpsertRequest
    {
        [Required]
        [Range(1000, 100000000, ErrorMessage = "Budget must be between 1,000 VND and 100,000,000 VND.")]
        public int BudgetVnd { get; set; }

        [Required]
        [Range(5, 1440, ErrorMessage = "Cooking time limit must be between 5 minutes and 1,440 minutes.")]
        public int TimeLimitMin { get; set; }
    }
}
