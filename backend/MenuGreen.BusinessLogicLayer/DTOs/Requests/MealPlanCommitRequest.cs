namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanCommitRequest
    {
        public DateOnly? Date { get; set; }
        public bool MarkAllCompleted { get; set; } = true;
    }
}
