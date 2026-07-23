using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CreateMealPlanFromDailyMenuRequest
    {
        [Required]
        public DateOnly PlannedDate { get; set; }

        public int? TargetCalories { get; set; }

        [Required]
        public List<DailyMenuPlanItemRequest> Items { get; set; } = new();
    }

    public class DailyMenuPlanItemRequest
    {
        [Required]
        public string MealType { get; set; } = string.Empty;

        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public int? TargetCalories { get; set; }
        public TimeOnly? ScheduledTime { get; set; }

        /// <summary>
        /// Nguồn gốc: "user" = tạo tay ở tab Kế hoạch,
        /// "gym" = tạo tự động từ AI Gym Goals ở tab Mục tiêu.
        /// </summary>
        public string? Origin { get; set; }
    }
}
