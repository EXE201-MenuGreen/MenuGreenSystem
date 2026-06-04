namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CompleteOnboardingRequest
    {
        /// <summary>Optional user-adjusted daily calorie target from onboarding slider.</summary>
        public int? TargetCalories { get; set; }
    }
}
