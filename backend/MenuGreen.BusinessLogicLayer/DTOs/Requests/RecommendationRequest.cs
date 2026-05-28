using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecommendationRequest
    {
        [Range(0, int.MaxValue)]
        public int? TargetCalories { get; set; }

        [Range(0, int.MaxValue)]
        public int? BudgetVnd { get; set; }

        [Range(0, int.MaxValue)]
        public int? LimitMinutes { get; set; }

        [Range(1, 20)]
        public int Top { get; set; } = 10;
    }
}
