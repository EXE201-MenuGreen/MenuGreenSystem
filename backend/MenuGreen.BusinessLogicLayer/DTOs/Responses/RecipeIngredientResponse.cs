using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class RecipeIngredientResponse
    {
        public Guid IngredientId { get; set; }
        public string IngredientName { get; set; } = string.Empty;
        public decimal Quantity { get; set; }
        public string Unit { get; set; } = string.Empty;
        public string? Notes { get; set; }
    }
}
