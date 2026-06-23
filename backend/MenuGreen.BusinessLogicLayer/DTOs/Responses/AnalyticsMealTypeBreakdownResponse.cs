namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsMealTypeBreakdownResponse
    {
        public MealTypeDistribution AverageDistribution { get; set; } = new();
        public Dictionary<string, MealTypeDistribution> ByDayOfWeek { get; set; } = new();
        public Dictionary<string, MealTypeCalories> CaloriesByMealType { get; set; } = new();
        public string Insights { get; set; } = string.Empty;
    }

    public class MealTypeDistribution
    {
        public decimal Breakfast { get; set; }
        public decimal Lunch { get; set; }
        public decimal Dinner { get; set; }
        public decimal Snack { get; set; }
    }

    public class MealTypeCalories
    {
        public decimal Avg { get; set; }
        public decimal Target { get; set; }
    }
}
