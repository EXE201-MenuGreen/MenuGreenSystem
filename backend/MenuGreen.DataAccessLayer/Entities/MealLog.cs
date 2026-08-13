using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealLog
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public string? MealType { get; set; }
        public decimal? QuantityG { get; set; }
        public decimal? CaloriesKcal { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public string? IngredientSnapshotJson { get; set; }
        public decimal? ConsumptionRatio { get; set; }
        public string? SourceType { get; set; }
        public string? CustomName { get; set; }
        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }
        public bool IsFromMealPlan { get; set; }

        public virtual User? User { get; set; }
        public virtual MealPlanItem? MealPlanItem { get; set; }
        public virtual Food? Food { get; set; }
        public virtual Recipe? Recipe { get; set; }
    }
}
