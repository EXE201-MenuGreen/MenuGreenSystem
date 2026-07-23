using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class DailyStarterStartLogResponse
    {
        public string SuggestedMealType { get; set; } = "Breakfast"; // Breakfast | Lunch | Dinner | Snack
        public List<FoodResponse> SuggestedFoods { get; set; } = new();
        public Guid LoggedMealId { get; set; }
        public FoodResponse? LoggedFood { get; set; }
    }
}
