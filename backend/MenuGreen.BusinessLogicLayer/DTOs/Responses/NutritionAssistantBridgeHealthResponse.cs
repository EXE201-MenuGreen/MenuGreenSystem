using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionAssistantBridgeHealthResponse
    {
        public bool WorkerConfigured { get; set; }
        public string WorkerUrl { get; set; } = string.Empty;
        public bool WorkerReachable { get; set; }
        public int? StatusCode { get; set; }
        public string? WorkerService { get; set; }
        public string? Error { get; set; }
        public DateTimeOffset CheckedAt { get; set; }
    }
}
