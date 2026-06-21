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

        /// <summary>Loại món có dị ứng trùng user (mặc định true khi có userId).</summary>
        public bool ExcludeUserAllergies { get; set; } = true;

        /// <summary>Vietnamese taste region preference: north, central, south.</summary>
        public string? Region { get; set; }

        /// <summary>Typical meal context: eat-out, home-cooked, mixed.</summary>
        public string? MealContext { get; set; }

        /// <summary>Boost familiar Vietnamese foods and portions.</summary>
        public bool LocalFriendly { get; set; }
    }
}
