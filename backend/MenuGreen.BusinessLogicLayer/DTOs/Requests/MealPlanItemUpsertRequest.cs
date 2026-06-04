using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanItemUpsertRequest
    {
        [Required]
        public string MealType { get; set; } = string.Empty;

        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }

        public DateOnly? PlannedDate { get; set; }
        public TimeOnly? ScheduledTime { get; set; }
        public int? TargetCalories { get; set; }
        public bool IsCompleted { get; set; }
    }
}
