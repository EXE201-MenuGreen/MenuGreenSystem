using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class GroceryListResponse
    {
        public Guid MealPlanId { get; set; }
        public int EstimatedTotalVnd { get; set; }
        public List<GroceryListItemResponse> Items { get; set; } = new();
    }

    public class GroceryListItemResponse
    {
        public Guid IngredientId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Quantity { get; set; }
        public string Unit { get; set; } = string.Empty;
        public int EstimatedPriceVnd { get; set; }
    }
}
