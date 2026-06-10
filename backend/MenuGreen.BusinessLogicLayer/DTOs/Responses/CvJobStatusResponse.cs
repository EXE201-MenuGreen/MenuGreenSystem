using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CvJobStatusResponse
    {
        [JsonPropertyName("job_id")]
        public string JobId { get; set; } = string.Empty;

        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty; // queued | processing | done | failed

        [JsonPropertyName("result")]
        public CvInferenceResponse? Result { get; set; }

        [JsonPropertyName("error")]
        public string? Error { get; set; }
    }
}
