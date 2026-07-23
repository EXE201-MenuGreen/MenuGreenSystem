using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanItemResponse
    {
        public Guid Id { get; set; }
        public Guid MealPlanId { get; set; }
        public string? MealType { get; set; }
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public DateOnly? PlannedDate { get; set; }
        public TimeOnly? ScheduledTime { get; set; }
        public int? TargetCalories { get; set; }
        public decimal? QuantityG { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public string? CustomName { get; set; }
        public bool IsCompleted { get; set; }
        public Guid? MealLogId { get; set; }
        public string? FoodName { get; set; }
        public string? RecipeName { get; set; }
        public string? SourceEntityType { get; set; }
        public string? Status { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public int? ProteinG { get; set; }
        public int? CarbsG { get; set; }
        public int? FatG { get; set; }

        /// <summary>
        /// Nguồn gốc: "user" = tạo tay ở tab Kế hoạch,
        /// "gym" = tạo tự động từ AI Gym Goals ở tab Mục tiêu.
        /// </summary>
        public string? Origin { get; set; }
    }
}
