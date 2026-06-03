using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecommendationPreviewRequest
    {
        [MaxLength(50)]
        public string? Type { get; set; }

        public int? TargetCalories { get; set; }
        public int? BudgetVnd { get; set; }
        public int? LimitMinutes { get; set; }
        [MaxLength(100)]
        public string? Goal { get; set; }
        [MaxLength(50)]
        public string? MealType { get; set; }
    }
}
