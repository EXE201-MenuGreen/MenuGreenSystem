using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealLogResponse
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
        public decimal? ConsumptionRatio { get; set; }
        public System.Collections.Generic.List<PortionIngredientResponse> Ingredients { get; set; } = new();
        public string? SourceType { get; set; }
        public string? CustomName { get; set; }
        public string? Notes { get; set; }
        public DateTime? LoggedAt { get; set; }
        public Guid? MealPlanItemId { get; set; }
        public bool IsFromMealPlan { get; set; }
        public string? FoodName { get; set; }
        public string? RecipeTitle { get; set; }
        public string? DisplayName { get; set; }
        public string? DisplayPortion { get; set; }
    }
}
