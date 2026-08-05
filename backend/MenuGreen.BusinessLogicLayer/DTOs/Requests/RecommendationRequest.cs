using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecommendationRequest
    {
        [Range(0, int.MaxValue)]
        public int? TargetCalories { get; set; }

        /// <summary>
        /// Optional lower calorie bound for every suggested food/recipe item.
        /// </summary>
        [Range(0, int.MaxValue)]
        public int? MinCalories { get; set; }

        /// <summary>
        /// Optional upper calorie bound for every suggested food/recipe item.
        /// </summary>
        [Range(0, int.MaxValue)]
        public int? MaxCalories { get; set; }

        /// <summary>
        /// Optional daily protein range. Recommendations convert this range
        /// to a typical per-meal range (one quarter of the daily value).
        /// </summary>
        [Range(0, double.MaxValue)]
        public decimal? MinProteinG { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? MaxProteinG { get; set; }

        [Range(0, int.MaxValue)]
        public int? BudgetVnd { get; set; }

        [Range(0, int.MaxValue)]
        public int? LimitMinutes { get; set; }

        [Range(1, 20)]
        public int Top { get; set; } = 10;

        /// <summary>
        /// Optional local calendar date used to scope deterministic daily recommendations.
        /// </summary>
        public DateOnly? Date { get; set; }

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
