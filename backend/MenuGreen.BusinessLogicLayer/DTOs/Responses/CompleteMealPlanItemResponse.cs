using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CompleteMealPlanItemResponse
    {
        public MealPlanItemResponse Item { get; set; } = new();
        public MealLogResponse MealLog { get; set; } = new();
    }
}
