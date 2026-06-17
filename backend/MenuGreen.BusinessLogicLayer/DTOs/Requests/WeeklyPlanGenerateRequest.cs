using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class WeeklyPlanGenerateRequest
    {
        public DateOnly StartDate { get; set; }
        public int TargetCaloriesPerDay { get; set; }
        public MealPreferencesDto MealPreferences { get; set; } = new();
    }

    public class MealPreferencesDto
    {
        public bool Breakfast { get; set; } = true;
        public bool Lunch { get; set; } = true;
        public bool Dinner { get; set; } = true;
        public int Snacks { get; set; } = 1;
    }
}
