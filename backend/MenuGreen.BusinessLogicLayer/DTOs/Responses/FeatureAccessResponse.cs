using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class FeatureAccessResponse
    {
        public string Tier { get; set; } = "free";
        public IReadOnlyList<string> Entitlements { get; set; } = Array.Empty<string>();
        public IReadOnlyList<string> FeatureGroups { get; set; } = Array.Empty<string>();
        public DateTime? ExpiresAt { get; set; }
    }
}
