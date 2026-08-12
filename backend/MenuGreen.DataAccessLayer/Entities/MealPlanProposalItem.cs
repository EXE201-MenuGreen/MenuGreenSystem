using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class MealPlanProposalItem
    {
        public Guid Id { get; set; }
        public Guid ProposalId { get; set; }
        public string Action { get; set; } = "Add";
        public DateOnly PlannedDate { get; set; }
        public string MealType { get; set; } = "snack";
        public Guid? ExistingMealPlanItemId { get; set; }
        public Guid? FoodId { get; set; }
        public Guid? RecipeId { get; set; }
        public decimal? QuantityG { get; set; }
        public int? TargetCalories { get; set; }
        public decimal? ProteinG { get; set; }
        public decimal? CarbsG { get; set; }
        public decimal? FatG { get; set; }
        public string? IngredientSnapshotJson { get; set; }
        public int SortOrder { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual MealPlanProposal? Proposal { get; set; }
        public virtual MealPlanItem? ExistingMealPlanItem { get; set; }
        public virtual Food? Food { get; set; }
        public virtual Recipe? Recipe { get; set; }
    }
}
