using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CreatePtReviewReportRequest
    {
        [Required]
        public DateOnly WeekStartDate { get; set; }

        [Range(1, 30)]
        public int ExpirationDays { get; set; } = 7;

        [StringLength(30)]
        public string? RequestType { get; set; }

        [StringLength(1000)]
        public string? StudentNote { get; set; }

        [Range(typeof(decimal), "20", "400")]
        public decimal? CheckInWeight { get; set; }

        [Range(typeof(decimal), "1", "75")]
        public decimal? CheckInBodyFat { get; set; }

        [Range(0, 7)]
        public int? TrainingDaysCount { get; set; }

        [StringLength(100)]
        public string? BodyFeeling { get; set; }
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
