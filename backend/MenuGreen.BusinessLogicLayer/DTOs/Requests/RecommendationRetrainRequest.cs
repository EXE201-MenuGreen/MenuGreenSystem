using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class RecommendationRetrainRequest
    {
        public bool DryRun { get; set; } = true;

        [Range(1, 1000)]
        public int MinimumFeedbackCount { get; set; } = 3;

        [Range(7, 3650)]
        public int LookbackDays { get; set; } = 365;
    }
}
