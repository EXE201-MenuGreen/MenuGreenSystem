using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanUpsertRequest
    {
        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string PlanType { get; set; } = string.Empty;

        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public int? TargetCalories { get; set; }
        [Range(0, 10000)]
        public int? MinCalories { get; set; }
        [Range(0, 10000)]
        public int? MaxCalories { get; set; }
        [StringLength(2000)]
        public string? CoachNotes { get; set; }
        public string? GeneratedBy { get; set; }
        public bool IsActive { get; set; } = true;
        public List<MealPlanItemUpsertRequest>? Items { get; set; }
    }

    /// DTO to create an empty plan (user creates plan first, adds items later).
    public class CreateEmptyPlanRequest
    {
        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string PlanType { get; set; } = string.Empty;

        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public int? TargetCalories { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
