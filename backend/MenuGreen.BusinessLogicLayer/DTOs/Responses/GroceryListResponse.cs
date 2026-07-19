using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class GroceryListResponse
    {
        public Guid MealPlanId { get; set; }
        public int EstimatedTotalVnd { get; set; }
        public List<GroceryListItemResponse> Items { get; set; } = new();
        public List<GroceryListDayResponse> Days { get; set; } = new();
        public List<ShoppingTripResponse> ShoppingTrips { get; set; } = new();
    }

    public class GroceryListDayResponse
    {
        public DateOnly PlannedDate { get; set; }
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
        public bool IsWeeklyStock { get; set; }
    }

    public class ShoppingTripResponse
    {
        public DateOnly ShoppingDate { get; set; }
        public bool IsInitialTrip { get; set; }
        public int EstimatedTotalVnd { get; set; }
        public List<GroceryCoveredMealResponse> CoveredMeals { get; set; } = new();
        public List<GroceryListItemResponse> Items { get; set; } = new();
    }

    public class GroceryCoveredMealResponse
    {
        public DateOnly PlannedDate { get; set; }
        public string MealType { get; set; } = string.Empty;
    }
}
