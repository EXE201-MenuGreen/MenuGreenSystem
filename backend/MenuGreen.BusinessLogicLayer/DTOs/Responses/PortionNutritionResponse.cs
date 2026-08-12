using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class PortionNutritionResponse
    {
        public int Version { get; set; } = 1;
        public Guid? RecipeId { get; set; }
        public Guid? FoodId { get; set; }
        public decimal QuantityG { get; set; }
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
        public List<PortionIngredientResponse> Ingredients { get; set; } = new();
    }

    public class PortionIngredientResponse
    {
        public Guid IngredientId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal BaseQuantity { get; set; }
        public decimal Quantity { get; set; }
        public string Unit { get; set; } = string.Empty;
        public decimal CaloriesKcal { get; set; }
        public decimal ProteinG { get; set; }
        public decimal CarbsG { get; set; }
        public decimal FatG { get; set; }
    }
}
