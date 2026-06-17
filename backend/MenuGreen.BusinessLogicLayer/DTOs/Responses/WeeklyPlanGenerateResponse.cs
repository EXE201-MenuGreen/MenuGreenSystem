using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class WeeklyPlanGenerateResponse
    {
        public Guid Id { get; set; }
        public DateOnly WeekStartDate { get; set; }
        public List<WeeklyDayPlanDto> Days { get; set; } = new();
    }

    public class WeeklyDayPlanDto
    {
        public DateOnly Date { get; set; }
        public List<WeeklyMealDto> Meals { get; set; } = new();
        public decimal TotalCalories { get; set; }
    }

    public class WeeklyMealDto
    {
        public string Type { get; set; } = string.Empty; // breakfast, lunch, dinner, snack
        public List<RecommendationItemResponse> Items { get; set; } = new();
        public decimal TotalCalories { get; set; }
    }
}
