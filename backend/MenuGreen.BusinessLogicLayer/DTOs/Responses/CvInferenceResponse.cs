using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CvInferenceResponse
    {
        [JsonPropertyName("job_id")]
        public string JobId { get; set; } = string.Empty;

        [JsonPropertyName("request_id")]
        public string RequestId { get; set; } = string.Empty;

        [JsonPropertyName("api_version")]
        public string ApiVersion { get; set; } = "v1";

        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;

        [JsonPropertyName("processing_time_ms")]
        public double? ProcessingTimeMs { get; set; }

        [JsonPropertyName("luong_tin_cay_chung")]
        public string? LuongTinCayChung { get; set; }

        [JsonPropertyName("nguyen_lieu_tho_quet_duoc")]
        public List<CvIngredientItem>? NguyenLieuThoQuetDuoc { get; set; }

        [JsonPropertyName("danh_sach_mon_an_goi_y")]
        public List<CvSuggestedDish>? DanhSachMonAnGoiY { get; set; }

        [JsonPropertyName("error_code")]
        public string? ErrorCode { get; set; }

        [JsonPropertyName("error_message")]
        public string? ErrorMessage { get; set; }

        [JsonIgnore]
        public string? Message { get; set; }
    }
}
