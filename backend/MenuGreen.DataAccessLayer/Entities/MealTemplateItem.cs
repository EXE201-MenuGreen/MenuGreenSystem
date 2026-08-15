using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealTemplateItem
    {
        public Guid Id { get; set; }
        public Guid MealTemplateId { get; set; }
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public string? CustomName { get; set; }
        public string? SourceType { get; set; }
        public string MealType { get; set; } = "Snack";
        public decimal QuantityG { get; set; }
        public decimal? CaloriesKcal { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public string? IngredientSnapshotJson { get; set; }
        public string? Notes { get; set; }
        public int SortOrder { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual MealTemplate? MealTemplate { get; set; }
        public virtual Food? Food { get; set; }
        public virtual Recipe? Recipe { get; set; }
    }
}
