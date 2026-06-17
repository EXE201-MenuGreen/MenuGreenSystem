using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AiAssistantContextResponse
    {
        public ProfileSummaryResponse? Profile { get; set; }
        public HealthProfileResponse? HealthProfile { get; set; }
        public List<string> Allergies { get; set; } = new();
        public NutritionSummaryResponse? RecentNutrition { get; set; }
    }
}
