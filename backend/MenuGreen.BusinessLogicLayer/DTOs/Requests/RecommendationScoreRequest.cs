using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecommendationScoreRequest
    {
        [Range(0, int.MaxValue)]
        public int? TargetCalories { get; set; }

        [Range(0, int.MaxValue)]
        public int? BudgetVnd { get; set; }

        [Range(0, int.MaxValue)]
        public int? LimitMinutes { get; set; }

        public bool ExcludeUserAllergies { get; set; } = true;
    }
}
