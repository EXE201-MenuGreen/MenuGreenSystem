using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UserMealPlanUpsertRequest
    {
        [Required]
        public DateOnly PlannedDate { get; set; }

        public string? Title { get; set; }
        public int? TargetCalories { get; set; }

        [Required]
        [MinLength(1)]
        public List<MealPlanItemUpsertRequest> Items { get; set; } = new();
    }
}
