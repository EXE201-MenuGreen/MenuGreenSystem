using System;
using System.Collections.Generic;
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

        /// <summary>
        /// Nguồn gốc: "user" = tạo tay ở tab Kế hoạch,
        /// "gym" = tạo tự động từ AI Gym Goals ở tab Mục tiêu.
        /// </summary>
        public string? Origin { get; set; }

        public string? CustomName { get; set; }
        public double? QuantityG { get; set; }
        public List<MealPlanIngredientPortionRequest>? Ingredients { get; set; }
    }

    public class MealPlanItemReplaceRequest
    {
        [Required]
        public Guid NewFoodId { get; set; }
    }
}
