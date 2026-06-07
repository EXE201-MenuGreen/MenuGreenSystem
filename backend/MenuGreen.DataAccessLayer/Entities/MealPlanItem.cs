using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealPlanItem
    {
        public Guid Id { get; set; }
        public Guid MealPlanId { get; set; }
        public string? MealType { get; set; } // BREAKFAST / LUNCH / DINNER / SNACK
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public DateOnly? PlannedDate { get; set; }
        public TimeOnly? ScheduledTime { get; set; }
        public int? TargetCalories { get; set; }
        public bool IsCompleted { get; set; } = false;
        public DateTime? CreatedAt { get; set; }

        // Navigation properties
        public virtual MealPlanHeader? MealPlanHeader { get; set; }
        public virtual Food? Food { get; set; }
        public virtual Recipe? Recipe { get; set; }
    }
}
