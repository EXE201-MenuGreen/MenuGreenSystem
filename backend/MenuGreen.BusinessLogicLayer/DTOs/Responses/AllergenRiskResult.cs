using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AllergenRiskResult
    {
        public List<string> MatchedAllergens { get; set; } = new();
        public string AllergyRiskLevel { get; set; } = "none";
        public bool IsSafeForUser { get; set; } = true;
    }
}
