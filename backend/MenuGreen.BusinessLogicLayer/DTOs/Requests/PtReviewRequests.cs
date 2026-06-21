using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CreatePtReviewReportRequest
    {
        [Required]
        public DateOnly WeekStartDate { get; set; }

        public int ExpirationDays { get; set; } = 7;
    }

    public class PtSubmitReviewRequest
    {
        [Required]
        [StringLength(1000)]
        public string Comment { get; set; } = string.Empty;

        public int? SuggestedCalorieTarget { get; set; }
        public int? SuggestedProteinTarget { get; set; }

        public List<PtSuggestedChangeDto> SuggestedChanges { get; set; } = new();
    }

    public class PtSuggestedChangeDto
    {
        [Required]
        public string DayOfWeek { get; set; } = string.Empty; // e.g. "Wednesday"

        [Required]
        public string MealType { get; set; } = string.Empty; // e.g. "PreWorkout"

        [Required]
        public string Action { get; set; } = "Replace"; // Replace, Add, Remove

        public Guid? OldFoodId { get; set; }
        public Guid? NewFoodId { get; set; }
        public Guid? NewRecipeId { get; set; }
        public string? Notes { get; set; }
    }
}
