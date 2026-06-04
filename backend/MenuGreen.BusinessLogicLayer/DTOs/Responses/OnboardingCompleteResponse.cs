namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class OnboardingCompleteResponse
    {
        public bool SnapshotCreated { get; set; }
        public ProfileCompletionResponse Completion { get; set; } = new();
        public HealthProfileResponse? HealthProfile { get; set; }
    }
}
