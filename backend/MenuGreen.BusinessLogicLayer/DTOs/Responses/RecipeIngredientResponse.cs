using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecipeIngredientResponse
    {
        public Guid IngredientId { get; set; }
        public string IngredientName { get; set; } = string.Empty;
        public decimal Quantity { get; set; }
        public string Unit { get; set; } = string.Empty;
        public decimal NutritionBasisQuantity { get; set; } = 100m;
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
        public string? Notes { get; set; }
    }
}
