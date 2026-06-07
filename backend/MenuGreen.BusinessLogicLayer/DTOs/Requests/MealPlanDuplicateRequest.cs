namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class MealPlanDuplicateRequest
    {
        public DateOnly? SourceStartDate { get; set; }
        public required DateOnly TargetStartDate { get; set; }
    }
}
