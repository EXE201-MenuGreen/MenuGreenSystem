using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    /// <summary>
    /// Body for POST /api/PtReview/coach/reports/{reportId}/review.
    /// Used when a Coach (logged-in) submits a review for a Gymer's weekly report.
    /// The optional <see cref="AdjustMealPlanItems"/> allow inline edit of the
    /// Gymer's meal plan covering that week.
    /// </summary>
    public class PtSubmitCoachReviewRequest
    {
        [Required]
        [StringLength(1000)]
        public string Comment { get; set; } = string.Empty;

        public int? SuggestedCalorieTarget { get; set; }
        public int? SuggestedProteinTarget { get; set; }

        public List<MealPlanAdjustmentItem>? AdjustMealPlanItems { get; set; }
    }

    /// <summary>
    /// One adjustment the Coach wants to apply to a Gymer's meal plan within the
    /// report's week. Inline edit on the report screen.
    /// </summary>
    public class MealPlanAdjustmentItem
    {
        /// <summary>The MealPlanHeader id (if known) or null to let the service create a daily plan.</summary>
        public Guid? PlanId { get; set; }

        /// <summary>The MealPlanItem id being affected (Remove / Replace).</summary>
        public Guid? ItemId { get; set; }

        /// <summary>"add" | "remove" | "replace"</summary>
        [Required]
        public string Action { get; set; } = "Replace";

        /// <summary>"breakfast" | "lunch" | "dinner" | "snack"</summary>
        [Required]
        public string MealType { get; set; } = "snack";

        public DateOnly PlannedDate { get; set; }

        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public int? TargetCalories { get; set; }
    }
}
