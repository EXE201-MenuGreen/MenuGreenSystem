using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class ProfileCompletionResponse
    {
        public bool IsCompleted { get; set; }
        public int CompletionPercent { get; set; }
        public IReadOnlyList<string> CompletedSteps { get; set; } = Array.Empty<string>();
        public IReadOnlyList<string> MissingSteps { get; set; } = Array.Empty<string>();
        public string NextStep { get; set; } = string.Empty;
    }
}
