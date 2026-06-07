namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class MealPlanStreakResponse
    {
        public int CurrentStreakDays { get; set; }
        public int BestStreakDays { get; set; }
        public decimal WeeklyAdherenceRate { get; set; }
    }
}
