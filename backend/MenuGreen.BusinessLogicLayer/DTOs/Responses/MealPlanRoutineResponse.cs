using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanRoutineResponse
    {
        public Guid UserId { get; set; }
        public TimeOnly BreakfastTime { get; set; }
        public TimeOnly LunchTime { get; set; }
        public TimeOnly DinnerTime { get; set; }
        public TimeOnly SnackTime { get; set; }
    }
}
