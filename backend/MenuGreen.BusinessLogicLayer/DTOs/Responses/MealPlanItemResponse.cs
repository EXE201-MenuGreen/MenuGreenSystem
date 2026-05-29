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
        public int? TargetCalories { get; set; }
        public bool IsCompleted { get; set; }
        public string? FoodName { get; set; }
        public string? RecipeName { get; set; }
    }
}
